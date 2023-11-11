defmodule DataAggregator.Records.Import.Record do
  @moduledoc """
  Resource representing a collection of records.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  relationships do
    belongs_to :import, Import do
      primary_key? true
      allow_nil? false
    end

    belongs_to :record, Record do
      api DataAggregator.Records
      primary_key? true
      allow_nil? false
    end
  end

  actions do
    defaults [:read, :destroy, :update]

    create :create do
      primary? true
      argument :import, Import, allow_nil?: true
      argument :record, Record, allow_nil?: true
      change manage_relationship(:import, :import, type: :append)
      change manage_relationship(:record, :record, type: :append)
      upsert? true
      upsert_fields [:import_id, :record_id]
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :create, args: [:import, :record]
  end

  postgres do
    table "import_records"
    repo DataAggregator.Repo
  end
end
