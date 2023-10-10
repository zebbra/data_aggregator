defmodule DataAggregator.Imports.Import do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  alias DataAggregator.Imports.StaticAsset
  alias DataAggregator.Imports.ImportFile
  alias DataAggregator.TaxonomyData.Record

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "import"

    attribute :name, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    attribute :version, :integer do
      allow_nil? false
      filterable? true
    end

    attribute :import_data, :map

    attribute :collection_id, :uuid do
      allow_nil? false
      filterable? true
    end

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
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    has_many :records, Record
    has_many :static_assets, StaticAsset
    has_many :import_files, ImportFile
  end
end
