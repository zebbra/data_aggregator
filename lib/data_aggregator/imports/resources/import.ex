defmodule DataAggregator.Imports.Import do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "imp"
    attribute :url, :string, allow_nil?: false
    timestamps(private?: false)
  end

  actions do
    defaults [:create, :update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, default: "url"

      prepare fn query, _ ->
        query
        |> Ash.Query.sort(Ash.Sort.parse_input!(__MODULE__, query.arguments.sort))
      end
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
    define :read, args: [:sort]
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end
end
