defmodule DataAggregator.Records.Encoding.RecordEncodingResult do
  @moduledoc """
  Resource representing a result of a single encoding of a `DataAggregator.Records.Record`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Records.Encoding.EncodingResultState
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  attributes do
    uuid_attribute :id, prefix: "rer"

    attribute :input, :map, allow_nil?: false, description: "The input data for the encoding"
    attribute :output, :map, allow_nil?: false, description: "The output data of the encoding"

    attribute :message, :string,
      allow_nil?: true,
      description: "A message describing the result of the encoding"

    attribute :catalog, Catalog,
      allow_nil?: false,
      description: "The catalog used for the encoding"

    attribute :state, EncodingResultState,
      allow_nil?: false,
      description: "The state of the encoding result"

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :record, Record
  end

  actions do
    defaults [:read, :destroy]

    read :filter_by_record do
      argument :record_id, :string, allow_nil?: false

      filter expr(record_id == ^arg(:record_id))
      prepare build(sort: [inserted_at: :desc])
    end

    create :create do
      primary? true
      argument :record, Record

      change manage_relationship(:record, :record, type: :append)
    end

    update :update do
      primary? true
      argument :record, Record

      change manage_relationship(:record, :record, type: :append)
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :filter_by_record, args: [:record_id]
  end

  postgres do
    table "record_encoding_results"
    repo DataAggregator.Repo
  end
end
