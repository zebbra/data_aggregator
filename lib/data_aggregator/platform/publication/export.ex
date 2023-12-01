defmodule DataAggregator.Platform.Publication.Export do
  @moduledoc """
  An export represents an exported set of records for a given consumer with a certain state
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Platform.Publication
  alias DataAggregator.Platform.Publication.Consumer
  alias DataAggregator.Platform.Publication.Record, as: ExportRecord

  attributes do
    uuid_attribute :id, prefix: "exp"

    attribute :name, :string, allow_nil?: false
    attribute :exported_at, :utc_datetime, allow_nil?: true
    attribute :started_at, :utc_datetime, allow_nil?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true
    attribute :mapping, :map, allow_nil?: true

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :consumer, Consumer

    has_many :export_records, DataAggregator.Platform.Publication.Record do
    end

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    many_to_many :records, DataAggregator.Records.Record do
      api DataAggregator.Records
      through ExportRecord
      join_relationship :export_records
    end
  end

  aggregates do
    count :records_count, :records
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
      argument :consumer, Consumer, allow_nil?: false
      argument :records, {:array, :struct}, allow_nil?: false

      change manage_relationship(:consumer, :consumer, type: :append)
      change manage_relationship(:records, :records, type: :append)
    end

    update :update_mapping do
      argument :mapping, :map, allow_nil?: true

      change Publication.Changes.UpdateMapping
    end

    update :update do
      primary? true
      argument :consumer, Consumer, allow_nil?: false
      argument :records, {:array, :struct}, allow_nil?: false

      change manage_relationship(:consumer, :consumer, type: :append)
      change manage_relationship(:records, :records, type: :append)
    end

    update :enqueue do
      accept []
      change transition_state(:queued)
      change Publication.Changes.EnqueueRunner
    end

    update :set_running do
      accept []
      change set_attribute(:state, :running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
    end

    update :set_failed do
    end

    update :run do
      accept []
      change Publication.Changes.SetTimeout
      change Publication.Changes.SetRunningBeforeTransaction
      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change Publication.Changes.ExportRecords
      change Publication.Changes.SetExportedAfterAction
      change load(:attachment)
      change load(:records_count)
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
    end

    action :publish, :map do
      argument :export, :struct, allow_nil?: false

      run Publication.Actions.PublishRecords
    end
  end

  code_interface do
    define_for DataAggregator.Platform
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :publish, action: :publish, args: [:export]
    define :update_mapping, action: :update_mapping, args: [:mapping]
    define :run
    define :enqueue
    define :set_exported
    define :set_running
    define :set_failed
    define :update_attachment, action: :update_attachment, args: [:attachment]
  end

  postgres do
    table "exports"
    repo DataAggregator.Repo
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
      base("/exports")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
