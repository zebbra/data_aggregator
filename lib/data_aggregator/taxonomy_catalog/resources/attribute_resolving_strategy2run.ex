defmodule DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy2Run do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy
  alias DataAggregator.Transition.Run

  attributes do
    uuid_attribute :id, prefix: "ars2r"

    timestamps()
  end

  graphql do
    type :attribute_resolving_strategy2run

    queries do
      get :get_attribute_resolving_strategy2run, :read
      list :list_attribute_resolving_strategies2runs, :read
    end

    mutations do
      create :create_attribute_resolving_strategy2run, :create
      update :update_attribute_resolving_strategy2run, :update
      destroy :destroy_attribute_resolving_strategy2run, :destroy
    end
  end

  json_api do
    type "attribute_resolving_strategy2run"

    routes do
      base("/attribute_resolving_strategies2runs")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  relationships do
    belongs_to :attribute_resolving_strategy, AttributeResolvingStrategy

    belongs_to :run, Run do
      api DataAggregator.Transition
    end
  end

  postgres do
    table "attribute_resolving_strategies2runs"
    repo DataAggregator.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.TaxonomyCatalog
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end
end
