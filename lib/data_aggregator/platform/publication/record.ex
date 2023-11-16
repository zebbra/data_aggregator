defmodule DataAggregator.Platform.Publication.Record do
  @moduledoc """
  Resource representing a collection of records which is exported to a certain consumer.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Records.Record

  relationships do
    belongs_to :export, Export do
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
      argument :export, Export, allow_nil?: true
      argument :record, Record, allow_nil?: true
      change manage_relationship(:export, :export, type: :append)
      change manage_relationship(:record, :record, type: :append)
      upsert? true
      upsert_fields [:export_id, :record_id]
    end
  end

  code_interface do
    define_for DataAggregator.Platform
    define :create, args: [:export, :record]
  end

  postgres do
    table "export_records"
    repo DataAggregator.Repo
  end
end
