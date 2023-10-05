defmodule DataAggregator.TaxonomyCatalog.Catalog do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Transition.RecordChangeEvent
  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy

  postgres do
    table "catalogs"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "catalog"

    attribute :version, :integer do
      allow_nil? false
      filterable? true
    end

    attribute :state, :string do
      allow_nil? false
      filterable? true
    end

    attribute :meta_data, :map

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
    has_one :attribute_resolving_strategy, AttributeResolvingStrategy
    has_many :record_change_events, RecordChangeEvent
  end
end
