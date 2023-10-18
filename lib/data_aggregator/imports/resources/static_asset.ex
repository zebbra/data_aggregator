defmodule DataAggregator.Imports.StaticAsset do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.ImportRecord

  postgres do
    table "static_assets"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "sa"

    attribute :url, :string, allow_nil?: false

    attribute :meta_data, :map

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "static_asset"

    routes do
      base("/static_assets")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :static_asset

    queries do
      get :get_static_asset, :read
      list :list_static_assets, :read
    end

    mutations do
      create :create_static_asset, :create
      update :update_static_asset, :update
      destroy :destroy_static_asset, :destroy
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
    belongs_to :import_record, ImportRecord
  end
end
