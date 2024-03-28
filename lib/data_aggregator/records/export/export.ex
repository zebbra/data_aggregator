defmodule DataAggregator.Records.Export do
  @moduledoc """
  An export represents an exported set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export.Changes

  attributes do
    uuid_attribute :id, prefix: "exp"

    attribute :name, :string, allow_nil?: false
    attribute :exported_at, :utc_datetime, allow_nil?: true
    attribute :started_at, :utc_datetime, allow_nil?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true
    attribute :mapping, :map, allow_nil?: true
    attribute :records_query, :term, allow_nil?: false
    attribute :exported_count, :integer, allow_nil?: false, default: 0
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
    calculate :export_progress, :float, expr(exported_count / rows_count)
    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn export, _opts -> export.attachment.url end
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
      transition :set_exported, from: :running, to: :exported
      transition :set_failed, from: :running, to: :failed
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :collection, Collection, allow_nil?: false

      change manage_relationship(:collection, :collection, type: :append)
    end

    update :update_mapping do
      argument :mapping, :map, allow_nil?: true

      change Changes.UpdateMapping
      change load(:attachment)
    end

    update :update do
      primary? true
      argument :records, {:array, :struct}, allow_nil?: true
    end

    update :enqueue do
      accept []
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
      change Changes.ExportRecords
      change Changes.SetExportedAfterAction
      change load(:attachment)
    end

    update :set_exported do
      accept []
      change transition_state(:exported)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change set_attribute(:exported_at, &DateTime.utc_now/0)
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
    prefix "export"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :update, [[:collection_id, nil], "updated", [:id, nil]]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
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
  end

  postgres do
    table "exports"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
      reference :attachment, on_delete: :delete, on_update: :update
      reference :job, on_delete: :nilify, on_update: :update
    end
  end

  graphql do
    type :export

    queries do
      get :get_export, :read
      list :list_exports, :read
    end

    mutations do
      create :create_export, :create
      update :update_export, :update
      destroy :destroy_export, :destroy
    end
  end

  json_api do
    type "export"

    routes do
      base "/exports"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
