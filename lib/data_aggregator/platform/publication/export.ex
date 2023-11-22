defmodule DataAggregator.Platform.Publication.Export do
  @moduledoc """
  An export represents an exported set of records for a given consumer with a certain state
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Platform.Publication
  alias DataAggregator.Platform.Publication.Consumer
  alias DataAggregator.Platform.Publication.Record, as: ExportRecord

  attributes do
    uuid_attribute :id, prefix: "exp"

    attribute :name, :string, allow_nil?: false

    attribute :exported_at, :utc_datetime, allow_nil?: true

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :consumer, Consumer

    has_many :export_records, DataAggregator.Platform.Publication.Record do
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

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :consumer, Consumer, allow_nil?: false
      argument :records, {:array, :struct}, allow_nil?: false

      change manage_relationship(:consumer, :consumer, type: :append)
      change manage_relationship(:records, :records, type: :append)
    end

    update :update do
      primary? true
      argument :consumer, Consumer, allow_nil?: false
      argument :records, {:array, :struct}, allow_nil?: false

      change manage_relationship(:consumer, :consumer, type: :append)
      change manage_relationship(:records, :records, type: :append)
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
    define :publish, action: :publish, args: [:export]
    define :get_by_id, action: :read, get_by: [:id]
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
