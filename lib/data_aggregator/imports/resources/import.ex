defmodule DataAggregator.Imports.Import do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

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
      argument :sort, :string, default: "url"

      prepare fn query, _ ->
        query
        |> Ash.Query.sort(Ash.Sort.parse_input!(__MODULE__, query.arguments.sort))
      end
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
