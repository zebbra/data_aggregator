defmodule DataAggregator.Platform.Import.Record do
  @moduledoc """
  Resource representing a collection of records.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Data.Record
  alias DataAggregator.Platform.Import

  relationships do
    belongs_to :import, Import do
      primary_key? true
      allow_nil? false
    end

    belongs_to :record, Record do
      api DataAggregator.Data
      primary_key? true
      allow_nil? false
    end
  end

  actions do
    defaults [:create, :read, :destroy]
  end

  postgres do
    table "import_records"
    repo DataAggregator.Repo
  end
end
