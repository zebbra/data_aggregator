defmodule DataAggregator.Records.Publication do
  @moduledoc """
  An publication represents an published set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication.Changes

  @type t :: %Publication{}

  attributes do
    uuid_attribute :id, prefix: "pub"

    attribute :name, :string, allow_nil?: false
    attribute :channel, :atom, allow_nil?: false
    attribute :published_at, :utc_datetime, allow_nil?: true
    attribute :started_at, :utc_datetime, allow_nil?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true
    attribute :records_query, :map, allow_nil?: false
    attribute :published_count, :integer, allow_nil?: false, default: 0
    attribute :rows_count, :integer, allow_nil?: false, default: 0

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    belongs_to :job, Job do
      api DataAggregator.Jobs
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
    end
  end

  calculations do
    calculate :publication_progress, :float, expr(published_count / rows_count)
    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn publication, _opts -> publication.attachment.url end
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
      transition :set_done, from: :running, to: :done
      transition :set_failed, from: :running, to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :desc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
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
      argument :collection, Collection, allow_nil?: false

      change manage_relationship(:collection, :collection, type: :append)
    end

    update :enqueue do
      accept []
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
      change set_attribute(:state, :running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
    end

    update :set_failed do
      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end

    update :run do
      accept []
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
      change transition_state(:done)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change set_attribute(:published_at, &DateTime.utc_now/0)
    end

    update :update_attachment do
      accept []
      argument :attachment, Attachment, allow_nil?: false
      change manage_relationship(:attachment, :attachment, type: :append)
      change load(:attachment)
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "publication"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :update, [[:collection_id, nil], "updated", [:id, nil]]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
  end

  code_interface do
    define_for DataAggregator.Records
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
      reference :collection, on_delete: :delete, on_update: :update
      reference :attachment, on_delete: :delete, on_update: :update
      reference :job, on_delete: :nilify, on_update: :update
    end
  end

  graphql do
    type :publication

    queries do
      get :get_publication, :read
      list :list_publications, :read
    end

    mutations do
      create :create_publication, :create
      update :update_publication, :update
      destroy :destroy_publication, :destroy
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
