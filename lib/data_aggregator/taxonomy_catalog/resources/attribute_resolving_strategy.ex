defmodule DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.TaxonomyCatalog.Catalog
  alias DataAggregator.TaxonomyCatalog.DwcAttribute

  postgres do
    table "attribute_resolving_strategies"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "attr_res_strategy"

    attribute :version, :integer do
      allow_nil? false
      filterable? true
    end

    attribute :state, :string do
      allow_nil? false
      filterable? true
    end

    attribute :meta_data, :map

    attribute :catalog_id, :uuid

    attribute :dwc_attribute_id, :uuid

    timestamps()
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

  relationships do
  end
end
