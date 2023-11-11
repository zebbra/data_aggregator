defmodule DataAggregator.Records.Collection do
  @moduledoc """
  Resource representing a collection of records.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  attributes do
    uuid_attribute :id, prefix: "col"

    attribute :items_to_digitize, :integer, allow_nil?: false, default: 0
    attribute :owner, :string, allow_nil?: false

    attribute :name, :string do
      allow_nil? false
    end

    attribute :code, :string do
      description "an iternationally valid code to identify the collection"
    end

    attribute :description, :string

    attribute :mapping, :map

    # allow sorting by inserted_at/updated_at
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :institution, DataAggregator.Platform.Institution do
      api DataAggregator.Platform
    end

    has_many :imports, DataAggregator.Records.Import do
      api DataAggregator.Records
    end

    has_many :records, DataAggregator.Records.Record do
      api DataAggregator.Records
    end
  end

  aggregates do
    count :records_count, :records
  end

  actions do
    defaults [:create, :update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "collections"
    repo DataAggregator.Repo
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  graphql do
    type :collection

    queries do
      get :get_collection, :read
      list :list_collections, :read
    end

    mutations do
      create :create_collection, :create
      update :update_collection, :update
      destroy :destroy_collection, :destroy
    end
  end

  json_api do
    type "collection"

    routes do
      base("/collections")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
