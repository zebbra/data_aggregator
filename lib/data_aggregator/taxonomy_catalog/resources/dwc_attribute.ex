defmodule DataAggregator.TaxonomyCatalog.DwcAttribute do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  alias DataAggregator.TaxonomyCatalog.Entity
  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy
  alias DataAggregator.Transition.RecordChangeEvent
  alias DataAggregator.Transition.Annotation

  postgres do
    table "dwc_attributes"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "dwc_attribute"

    attribute :name, :string

    attribute :entity_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

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
    has_many :annotations, Annotation
  end
end
