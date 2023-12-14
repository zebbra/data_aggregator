defmodule DataAggregator.Records.EncodedRecord do
  @moduledoc """
  Ash resource representing a encoded_record.

  > #### Info {: .info}
  >
  > All Darwin Core attributes are defined in `DataAggregator.DarwinCore.Schema` and included
  > by the `DataAggregator.DarwinCore.Resource` extension.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [
      AshUUID,
      AshGraphql.Resource,
      AshJsonApi.Resource,
      DataAggregator.DarwinCore.Resource
    ]

  alias DataAggregator.DarwinCore
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Record

  @default_limit 15
  def default_limit, do: @default_limit

  attributes do
    uuid_attribute :id, prefix: "enr"
    attribute :extra_data, :map
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :record, Record do
      allow_nil? false
      primary_key? true
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
      pagination offset?: true, default_limit: @default_limit, countable: true, required?: false
    end

    create :create do
      primary? true
      argument :record, Record, allow_nil?: false

      change Encoding.Changes.SetMandatoryAttributes
      change manage_relationship(:record, :record, type: :append)
    end

    create :upsert do
      description """
      Creates or updates a `EncodedRecord` from the given `params`.

      it contains all attributes, which the `DataAggregator.Records.Record` has as well. but gets its values from the encoding process.

      The encoded_record is associated with its `DataAggregator.Records.Record`

      """

      argument :record, Record, allow_nil?: false
      argument :params, :map, allow_nil?: false

      upsert? true
      upsert_fields [:extra_data | DarwinCore.Schema.prefixed_attribute_names()]

      change manage_relationship(:record, :record, type: :append)
    end

    action :encode, :map do
      argument :records, {:array, Record}, allow_nil?: false

      run Encoding.Actions.EncodeRecord
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :encode, args: [:records]
  end

  postgres do
    table "encoded_records"
    repo DataAggregator.Repo
  end

  graphql do
    type :encoded_record

    queries do
      get :get_encoded_record, :read
      list :list_encoded_records, :read
    end

    mutations do
      update :update_encoded_record, :update
      destroy :destroy_encoded_record, :destroy
    end
  end

  json_api do
    type "encoded_records"

    primary_key do
      keys([:id])
    end

    routes do
      base("/encoded_records")

      get(:read)
      index :read
      patch(:update)
      delete(:destroy)
    end
  end
end
