defmodule DataAggregator.Transition.Run do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Transition.ChangeEvent

  attributes do
    uuid_attribute :id, prefix: "run"

    timestamps private?: false, writable?: false
  end

  relationships do
    has_many :change_events, ChangeEvent do
      api DataAggregator.Transition
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Transition
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "runs"
    repo DataAggregator.Repo
  end

  graphql do
    type :run

    relationships [:record]

    queries do
      get :get_run, :read
      list :list_runs, :read
    end

    mutations do
      create :create_run, :create
      update :update_run, :update
      destroy :destroy_run, :destroy
    end
  end

  json_api do
    type "run"

    routes do
      base("/runs")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
