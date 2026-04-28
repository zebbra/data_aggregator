defmodule DataAggregator.Records.Export do
  @moduledoc """
  An export represents an exported set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Accounts.User
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction
  alias DataAggregator.Records.DataLayerType
  alias DataAggregator.Records.Export.Changes
  alias DataAggregator.Records.HeaderSourceType

  @type t :: %Export{}

  attributes do
    uuid_attribute :id, prefix: "exp", public?: true

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :exported_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :mapping, :map, allow_nil?: true, public?: true
    attribute :records_query, :map, allow_nil?: false, public?: true
    attribute :exported_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :rows_count, :integer, allow_nil?: false, default: 0, public?: true

    attribute :header_source, HeaderSourceType,
      allow_nil?: false,
      default: :collection_mapping,
      public?: true

    attribute :data_layer, DataLayerType, allow_nil?: false, default: :raw, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      public? true
      allow_nil? false
    end

    belongs_to :started_by, User, public?: true
    belongs_to :attachment, Attachment, public?: true
  end

  calculations do
    calculate :export_progress,
              :float,
              expr(if rows_count > 0, do: exported_count / rows_count, else: 1.0)

    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn exports, _opts ->
        Enum.map(exports, & &1.attachment.url)
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
      transition :enqueue, from: [:pending, :exported, :failed], to: :queued
      transition :run, from: [:pending, :exported, :failed, :queued], to: :running
      transition :set_running, from: [:pending, :exported, :failed, :queued], to: :running
      transition :set_exported, from: :running, to: :exported
      transition :set_failed, from: :running, to: :failed
      transition :cancel_export, from: [:running, :queued], to: :failed
    end
  end

  preparations do
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read]

    read :active do
      filter expr(state in [:running, :queued])
    end

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false

      change manage_relationship(:collection, type: :append)
    end

    update :update_mapping do
      argument :mapping, :map, allow_nil?: true
      require_atomic? false

      change Changes.UpdateMapping
      change load(:attachment)
    end

    update :update do
      primary? true
      argument :records, {:array, :struct}, allow_nil?: true
    end

    update :enqueue do
      accept [:started_by_id]
      require_atomic? false

      change Changes.SetCollectionExportingBeforeTransaction
      change transition_state(:queued)
      change Changes.EnqueueExporter
    end

    update :add_export_progress do
      accept []
      argument :exported, :integer, allow_nil?: false
      change atomic_update(:exported_count, expr(exported_count + ^arg(:exported)))
      change ensure_selected(:exported_count)
    end

    update :set_running do
      accept []
      require_atomic? false

      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
    end

    update :set_failed do
      accept []
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
      change Changes.ExportRecords
      change Changes.SetExportedAfterAction
      change load(:attachment)
    end

    update :set_exported do
      accept []
      require_atomic? false

      change transition_state(:exported)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change set_attribute(:exported_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :update_attachment do
      accept []
      argument :attachment, :struct, allow_nil?: false
      require_atomic? false

      change manage_relationship(:attachment, type: :append)
      change load(:attachment)
    end

    update :cancel_export do
      accept []
      require_atomic? false

      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end

    destroy :destroy do
      accept []

      primary? true

      change cascade_destroy(:attachment)
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "export"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
    publish :add_export_progress, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_running, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_exported, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_failed, [[:collection_id, nil], "updated", [:id, nil]]
  end

  code_interface do
    define :read
    define :active
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :update_mapping, action: :update_mapping, args: [:mapping]
    define :run
    define :enqueue
    define :set_exported
    define :set_running
    define :set_failed
    define :update_attachment, action: :update_attachment, args: [:attachment]
    define :add_export_progress, args: [:exported]
    define :cancel_export
  end

  postgres do
    table "exports"
    repo DataAggregator.Repo

    references do
      reference :collection,
        on_delete: :delete,
        on_update: :update,
        index?: true,
        deferrable: true
    end
  end

  json_api do
    type "exports"

    routes do
      base "/datasets/:collection_id/exports"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
