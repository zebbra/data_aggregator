defmodule DataAggregator.TaxonomyData.Record2Run do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyData.Record
  alias DataAggregator.Transition.Run

  postgres do
    table "records2runs"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "rec2run"

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "record2run"

    primary_key do
      keys([:record_id, :run_id])
      delimiter("_")
    end

    routes do
      base("/records2runs")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :record2run

    relationships [:record, :tag]

    queries do
      get :get_record2run, :read
      list :list_records2runs, :read
    end

    mutations do
      create :create_record2run, :create
      update :update_record2run, :update
      destroy :destroy_record2run, :destroy
    end
  end

  code_interface do
    define_for DataAggregator.TaxonomyData
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    belongs_to :record, Record, primary_key?: true, allow_nil?: false

    belongs_to :run, Run do
      api DataAggregator.Transition
      primary_key? true
      allow_nil? false
    end
  end
end
