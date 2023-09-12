defmodule DataAggregator.Imports.Dataset do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "datasets"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "dataset"

    attribute :unique_id, :string do
      allow_nil? false
      filterable? true
    end

    attribute :name, :string do
      allow_nil? false
      filterable? true
    end

    attribute :metaData, :map

    attribute :version, :integer do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :dataset

    queries do
      get :get_dataset, :read
      list :list_datasets, :read
    end

    mutations do
      create :create_dataset, :create
      update :update_dataset, :update
      destroy :destroy_dataset, :destroy
    end
  end

  code_interface do
    define_for DataAggregator.Imports
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    has_many :static_assets, DataAggregator.Imports.StaticAsset
    has_many :imports, DataAggregator.Imports.Import
    belongs_to :collection, DataAggregator.Imports.Collection
  end
end
