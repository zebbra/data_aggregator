defmodule DataAggregator.Records.Publication.PublishedRecord do
  @moduledoc """
  Resource representing the records of the collection, that have already been published
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, DataAggregator.DarwinCore.Resource]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  attributes do
    uuid_attribute :id, prefix: "pur", public?: true

    attribute :extra_data, :map, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      primary_key? true
      allow_nil? false
      public? true
    end

    belongs_to :publication, Publication do
      allow_nil? true
      public? true
    end

    belongs_to :record, Record do
      primary_key? true
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :unique_record_id, [:record_id]
    identity :by_collection, [:id, :collection_id]
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define :read
    define :create
    define :update
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "published_records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
      reference :publication, on_delete: :nothing, on_update: :update

      reference :record,
        on_delete: :delete,
        on_update: :update,
        match_with: [collection_id: :collection_id]
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
