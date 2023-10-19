defmodule DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.Collection
  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy2Run
  alias DataAggregator.TaxonomyCatalog.Catalog
  alias DataAggregator.TaxonomyCatalog.DwcAttribute

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :attribute_resolving_strategy

    queries do
      get :get_attribute_resolving_strategy, :read
      list :list_attribute_resolving_strategies, :read
    end

    mutations do
      create :create_attribute_resolving_strategy, :create
      update :update_attribute_resolving_strategy, :update
      destroy :destroy_attribute_resolving_strategy, :destroy
    end
  end

  json_api do
    type "attribute_resolving_strategy"

    routes do
      base("/attribute_resolving_strategies")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  attributes do
    uuid_attribute :id, prefix: "ars"

    attribute :do_not_encode, :boolean do
      default false
    end

    timestamps()
  end

  relationships do
    belongs_to :catalog, Catalog

    belongs_to :dwc_attribute, DwcAttribute

    has_many :attribute_resolving_strategies2runs, AttributeResolvingStrategy2Run

    belongs_to :collection, Collection do
      api DataAggregator.Imports
    end
  end

  postgres do
    table "attribute_resolving_strategies"
    repo DataAggregator.Repo
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
