defmodule DataAggregator.TaxonomyData.Tag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

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
