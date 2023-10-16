defmodule DataAggregator.Imports.ImportRecord2Run do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.ImportRecord
  alias DataAggregator.Transition.Run

  postgres do
    table "import_records2runs"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "import_record2run"

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "import_record2run"

    primary_key do
      keys([:import_record_id, :run_id])
      delimiter("_")
    end

    routes do
      base("/import_records2runs")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :import_record2run

    queries do
      get :get_import_record2run, :read
      list :list_import_records2runs, :read
    end

    mutations do
      create :create_import_record2run, :create
      update :update_import_record2run, :update
      destroy :destroy_import_record2run, :destroy
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
    belongs_to :import_record, ImportRecord, primary_key?: true, allow_nil?: false

    belongs_to :run, Run do
      api DataAggregator.Transition
      primary_key? true
      allow_nil? false
    end
  end
end
