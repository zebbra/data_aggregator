defmodule DataAggregator.TaxonomyCatalog.Entity do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "entities"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "entity"

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

  graphql do
    type :entity

    queries do
      get :get_entity, :read
      list :list_entities, :read
    end

    mutations do
      create :create_entity, :create
      update :update_entity, :update
      destroy :destroy_entity, :destroy
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
    has_many :parents, DataAggregator.TaxonomyCatalog.EntityEdge do
      destination_attribute :parent
    end
    has_many :children, DataAggregator.TaxonomyCatalog.EntityEdge do
      destination_attribute :child
    end
  end
end
