defmodule DataAggregator.Records.Publication do
  @moduledoc """
  An publication represents an published set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction
  alias DataAggregator.Records.Publication.Changes

  @type t :: %Publication{}

  attributes do
    uuid_attribute :id, prefix: "pub", public?: true

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :channel, :atom, allow_nil?: false, public?: true
    attribute :published_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :records_query, :map, allow_nil?: false, public?: true
    attribute :published_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :rows_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :center, :atom, allow_nil?: true, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection, public?: true
    belongs_to :attachment, Attachment, public?: true
  end

  calculations do
    calculate :publication_progress,
              :float,
              expr(published_count / if(rows_count == 0, do: 1, else: rows_count))

    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn publications, _opts ->
        Enum.map(publications, & &1.attachment.url)
      end

      load attachment: :url
    end

    calculate :attachment_byte_size, :integer, expr(attachment.byte_size)
    calculate :attachment_filename, :string, expr(attachment.filename)
  end

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :enqueue, from: [:pending, :done, :failed], to: :queued
      transition :run, from: [:pending, :done, :failed, :queued], to: :running
      transition :set_running, from: [:pending, :done, :failed, :queued], to: :running
      transition :set_done, from: :running, to: :done
      transition :set_failed, from: :running, to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :desc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, :update]

    read :by_collection do
      argument :collection_id, :string, allow_nil?: false
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 countable: true,
                 required?: false,
                 keyset?: true

      filter expr(collection_id == ^arg(:collection_id))
    end

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false

      change manage_relationship(:collection, :collection, type: :append)
    end

    update :enqueue do
      accept []
      require_atomic? false

      change Changes.SetCollectionPublishingBeforeTransaction
      change transition_state(:queued)
      change Changes.EnqueuePublisher
    end

    update :add_publication_progress do
      accept []
      argument :published, :integer, allow_nil?: false

      change atomic_update(:published_count, expr(published_count + ^arg(:published)))
      change ensure_selected(:published_count)
    end

    update :set_running do
      accept []
      require_atomic? false

      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
    end

    update :set_failed do
      require_atomic? false

      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :run do
      accept []
      require_atomic? false

      change Changes.SetTimeout
      change Changes.SetRunningBeforeTransaction
      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change Changes.PublishRecords
      change Changes.SetDoneAfterAction
      change load(:attachment)
    end

    update :set_done do
      accept []
      require_atomic? false

      change transition_state(:done)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change set_attribute(:published_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :update_attachment do
      accept []
      require_atomic? false

      argument :attachment, :struct, allow_nil?: false
      change manage_relationship(:attachment, :attachment, type: :append)
      change load(:attachment)
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "publication"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
    publish :set_running, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_done, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_failed, [[:collection_id, nil], "updated", [:id, nil]]
  end

  code_interface do
    define :read
    define :by_collection, args: [:collection_id]
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :run
    define :enqueue
    define :set_done
    define :set_running
    define :set_failed
    define :update_attachment, action: :update_attachment, args: [:attachment]
    define :add_publication_progress, args: [:published]
  end

  postgres do
    table "publications"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update, index?: true
      reference :attachment, on_delete: :delete, on_update: :update, index?: true
    end
  end

  json_api do
    type "publication"

    routes do
      base "/publications"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
