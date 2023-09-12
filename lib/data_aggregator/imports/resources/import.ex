defmodule DataAggregator.Imports.Import do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "import"
    attribute :url, :string, allow_nil?: false
    attribute :metaData, :map
    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :import

    queries do
      get :get_import, :read
      list :list_imports, :read
    end

    mutations do
      create :create_import, :create
      update :update_import, :update
      destroy :destroy_import, :destroy
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
    belongs_to :dataset, DataAggregator.Imports.Dataset
  end
end
