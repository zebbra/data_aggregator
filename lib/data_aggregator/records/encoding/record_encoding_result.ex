defmodule DataAggregator.Records.Encoding.RecordEncodingResult do
  @moduledoc """
  Resource representing a result of a single encoding of a `DataAggregator.Records.Record`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Encoding.EncodingResultState
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  attributes do
    uuid_attribute :id, prefix: "rer", public?: true

    attribute :input, :map,
      allow_nil?: false,
      description: "The input data for the encoding",
      public?: true

    attribute :output, :map,
      allow_nil?: false,
      description: "The output data of the encoding",
      public?: true

    attribute :message, :string,
      allow_nil?: true,
      description: "A message describing the result of the encoding",
      public?: true

    attribute :catalog, Catalog,
      allow_nil?: false,
      description: "The catalog used for the encoding",
      public?: true

    attribute :state, EncodingResultState,
      allow_nil?: false,
      description: "The state of the encoding result",
      public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :record, Record do
      public? true
      allow_nil? false
    end

    belongs_to :collection, Collection do
      primary_key? true
      public? true
      allow_nil? false
    end
  end

  actions do
    default_accept :*
    defaults [:read, :destroy]

    read :filter_by_record do
      argument :record_id, :string, allow_nil?: false

      filter expr(record_id == ^arg(:record_id))
      prepare build(sort: [inserted_at: :desc])
    end

    create :create do
      primary? true
      argument :record, :struct, allow_nil?: false
      argument :collection, :struct, allow_nil?: false

      change manage_relationship(:record, type: :append)
      change manage_relationship(:collection, type: :append)
    end

    update :update do
      primary? true
      argument :record, :struct
      require_atomic? false

      change manage_relationship(:record, type: :append)
    end
  end

  code_interface do
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

    references do
      reference :collection, on_delete: :delete, on_update: :update

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
