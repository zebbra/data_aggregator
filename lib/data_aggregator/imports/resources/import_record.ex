defmodule DataAggregator.Imports.ImportRecord do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.StaticAsset
  alias DataAggregator.Imports.ImportRecord2ImportFile
  alias DataAggregator.TaxonomyData.Record

  postgres do
    table "import_records"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "irec"

    attribute :unique_qualifier, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "import_records"

    routes do
      base("/import_records")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
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
    has_one :record, Record do
      api DataAggregator.TaxonomyData
    end

    has_many :static_assets, StaticAsset do
    end

    has_many :import_records2import_files, ImportRecord2ImportFile
  end
end
