defmodule DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "attribute_resolving_strategies"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "attr_res_strategy"

    attribute :name, :string

    attribute :url, :string

    attribute :catalog_id, :uuid do
      allow_nil? false
      filterable? true
    end

    attribute :dwc_attribute_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

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

  code_interface do
    define_for DataAggregator.TaxonomyCatalog
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
  end
end
