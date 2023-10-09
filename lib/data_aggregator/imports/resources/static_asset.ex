defmodule DataAggregator.Imports.StaticAsset do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Imports.Import

  postgres do
    table "static_assets"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "static_asset"

    attribute :url, :string, allow_nil?: false

    attribute :meta_data, :map

    attribute :import_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  # graphql do
  #   type :static_asset

  #   queries do
  #     get :get_static_asset, :read
  #     list :list_static_assets, :read
  #   end

  #   mutations do
  #     create :create_static_asset, :create
  #     update :update_static_asset, :update
  #     destroy :destroy_static_asset, :destroy
  #   end
  # end

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
  end
end
