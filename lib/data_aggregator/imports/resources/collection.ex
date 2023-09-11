defmodule DataAggregator.Imports.Collection do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  postgres do
    table "collections"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :metaData, :map
    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    has_many :imports, DataAggregator.Imports.Import
    belongs_to :provider, DataAggregator.Imports.Provider
  end
end
