defmodule DataAggregator.TaxonomyCatalog.EntityEdge do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.TaxonomyCatalog.Entity

  postgres do
    table "entity_edges"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "entity_edge"

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
    belongs_to :parent_entity, Entity do
      source_attribute :parent
    end
    belongs_to :child_entity, Entity do
      source_attribute :child
    end
  end
end
