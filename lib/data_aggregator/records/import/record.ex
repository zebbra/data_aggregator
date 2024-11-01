defmodule DataAggregator.Records.Import.Record do
  @moduledoc """
  Resource representing a collection of records.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  relationships do
    belongs_to :import, Import do
      primary_key? true
      allow_nil? false
      public? true
    end

    belongs_to :record, Record do
      primary_key? true
      allow_nil? false
      public? true
    end

    belongs_to :collection, Collection do
      allow_nil? false
      public? true
    end
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, :update]

    create :create do
      primary? true
      argument :import, :struct, allow_nil?: true
      argument :record, :struct, allow_nil?: true
      argument :collection, :struct, allow_nil?: true
      change manage_relationship(:import, type: :append)
      change manage_relationship(:record, type: :append)
      change manage_relationship(:collection, type: :append)
      upsert? true
      upsert_fields [:import_id, :record_id]
    end
  end

  code_interface do
    define :create, args: [:import, :record, :collection]
  end

  postgres do
    table "import_records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
      reference :import, on_delete: :delete, on_update: :update, index?: true

      reference :record,
        on_delete: :delete,
        on_update: :update,
        index?: true,
        match_with: [collection_id: :collection_id]
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
