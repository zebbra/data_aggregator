defmodule DataAggregator.TaxonomyCatalog.Entity do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.TaxonomyCatalog.EntityEdge
  alias DataAggregator.TaxonomyCatalog.DwcAttribute

  postgres do
    table "entities"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "entity"

    attribute :name, :string do
      allow_nil? false
    end

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
    has_many :dwc_attributes, DwcAttribute

    has_many :parents, EntityEdge do
      destination_attribute :parent_id
    end

    has_many :children, EntityEdge do
      destination_attribute :child_id
    end
  end
end
