defmodule DataAggregator.TaxonomyData.Tag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "tags"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "tag"

    attribute :tag, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :tag

    queries do
      get :get_tag, :read
      list :list_tags, :read
    end

    mutations do
      create :create_tag, :create
      update :update_tag, :update
      destroy :destroy_tag, :destroy
    end
  end

  code_interface do
    define_for DataAggregator.TaxonomyData
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
  end
end
