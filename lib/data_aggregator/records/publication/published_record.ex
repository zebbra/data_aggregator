defmodule DataAggregator.Records.Publication.PublishedRecord do
  @moduledoc """
  Resource representing the records of the collection, that have already been published
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, DataAggregator.DarwinCore.Resource]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  attributes do
    uuid_attribute :id, prefix: "pur", public?: true
    attribute :record_id, :string, primary_key?: true, allow_nil?: false, public?: true

    attribute :extra_data, :map, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
      public? true
    end

    belongs_to :publication, Publication do
      allow_nil? false
      public? true
    end
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  identities do
    identity :unique_record_id, [:record_id]
  end

  code_interface do
    define :read
    define :create
  end

  postgres do
    table "published_records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
      reference :publication, on_delete: :nothing, on_update: :update
    end
  end

  json_api do
    type "published_records"

    primary_key do
      keys [:id]
    end

    routes do
      base "/published_records"

      get :read
      index :read
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
