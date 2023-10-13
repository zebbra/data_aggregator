defmodule DataAggregator.Imports.Collection do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.Import
  alias DataAggregator.Imports.Institution

  postgres do
    table "collections"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "collection"

    attribute :name, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    attribute :institution_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "collection"

    routes do
      base("/collections")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
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

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    has_many :imports, Import
    belongs_to :institution, Institution
  end
end
