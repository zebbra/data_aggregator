defmodule DataAggregator.TaxonomyCatalog.Catalog do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy
  alias DataAggregator.TaxonomyCatalog.DwcAttribute
  alias DataAggregator.Transition.EncodingChangeEvent

  postgres do
    table "catalogs"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "cat"

    attribute :name, :string

    attribute :description, :string

    attribute :url, :string

    attribute :version, :integer do
      default 1
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "catalog"

    routes do
      base("/catalogs")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :catalog

    queries do
      get :get_catalog, :read
      list :list_catalogs, :read
    end

    mutations do
      create :create_catalog, :create
      update :update_catalog, :update
      destroy :destroy_catalog, :destroy
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
    has_many :dwc_attributes, DwcAttribute do
      destination_attribute :default_catalog_id
    end

    has_many :attribute_resolving_strategies, AttributeResolvingStrategy

    has_many :encoding_change_events, EncodingChangeEvent do
      api DataAggregator.Transition
    end
  end
end
