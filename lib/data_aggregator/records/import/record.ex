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
      primary_key? true
      allow_nil? false
      public? true
    end
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, :update]

    create :create do
      primary? true
      upsert? true
      upsert_fields [:collection_id, :import_id, :record_id]
    end
  end

  code_interface do
    define :create, args: [:import_id, :record_id, :collection_id]
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
