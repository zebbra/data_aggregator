defmodule DataAggregator.Taxonomy.DwcAttribute do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Taxonomy.Catalog

  attributes do
    uuid_attribute :id, prefix: "da"

    attribute :name, :string

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :default_catalog, Catalog
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Taxonomy
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "dwc_attributes"
    repo DataAggregator.Repo
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
end
