defmodule DataAggregator.Imports.ImportRecord do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.Collection
  alias DataAggregator.Imports.StaticAsset
  alias DataAggregator.TaxonomyData.Record

  attributes do
    uuid_attribute :id, prefix: "irec"

    attribute :unique_qualifier, :string do
      allow_nil? false
    end

    attribute :import_data, :map
    attribute :meta_data, :map

    timestamps(private?: false)
  end

  graphql do
    type :import_record

    queries do
      get :get_import_record, :read
      list :list_import_records, :read
    end

    mutations do
      create :create_import_record, :create
      update :update_import_record, :update
      destroy :destroy_import_record, :destroy
    end
  end

  json_api do
    type "import_records"

    routes do
      base("/import_records")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  relationships do
    belongs_to :collection, Collection

    has_one :record, Record do
      api DataAggregator.TaxonomyData
    end

    has_many :static_assets, StaticAsset do
    end
  end

  postgres do
    table "import_records"
    repo DataAggregator.Repo
  end

  actions do
    defaults [:create, :update, :destroy]

    read :read do
      primary? true

      argument :sort, :string do
        allow_nil? true
        default "id"
      end

      prepare fn query, _ ->
        query
        |> Ash.Query.sort(Ash.Sort.parse_input!(__MODULE__, query.arguments.sort))
      end
    end
  end

  code_interface do
    define_for DataAggregator.Imports

    define :read, args: [{:optional, :sort}]

    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end
end
