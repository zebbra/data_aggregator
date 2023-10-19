defmodule DataAggregator.TaxonomyCatalog.DwcAttribute do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy
  alias DataAggregator.TaxonomyCatalog.Catalog
  alias DataAggregator.Transition.Annotation
  alias DataAggregator.Transition.ChangeEvent

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :dwc_attribute

    queries do
      get :get_dwc_attribute, :read
      list :list_dwc_attributes, :read
    end

    mutations do
      create :create_dwc_attribute, :create
      update :update_dwc_attribute, :update
      destroy :destroy_dwc_attribute, :destroy
    end
  end

  json_api do
    type "dwc_attribute"

    routes do
      base("/dwc_attributes")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  attributes do
    uuid_attribute :id, prefix: "da"

    attribute :name, :string

    # further attributes to describe a dwc-attribute

    timestamps()
  end

  relationships do
    belongs_to :catalog, Catalog do
      source_attribute :default_catalog_id
    end

    has_many :attribute_resolving_strategies, AttributeResolvingStrategy

    has_many :change_events, ChangeEvent do
      api DataAggregator.Transition
    end

    has_many :annotations, Annotation do
      api DataAggregator.Transition
    end
  end

  postgres do
    table "dwc_attributes"
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
