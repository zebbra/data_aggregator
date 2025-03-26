defmodule DataAggregator.Records.ValidatedRecord do
  @moduledoc """
  Ash resource representing a validated_record.

  > #### Info {: .info}
  >
  > All Darwin Core attributes are defined in `DataAggregator.DarwinCore.Schema` and included
  > by the `DataAggregator.DarwinCore.Resource` extension.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [
      AshUUID,
      AshJsonApi.Resource,
      DataAggregator.DarwinCore.Resource
    ]

  alias __MODULE__
  alias DataAggregator.DarwinCore
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Validation
  alias DataAggregator.Records.Validation.Changes.SetMandatoryAttributes

  @type t :: %ValidatedRecord{}

  attributes do
    uuid_attribute :id, prefix: "apr", public?: true
    attribute :extra_data, :map, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :record, Record do
      allow_nil? false
      public? true
    end

    belongs_to :collection, Collection do
      primary_key? true
      allow_nil? false
      public? true
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      argument :record, :struct, allow_nil?: false
      argument :collection, :struct, allow_nil?: false

      upsert? true
      upsert_identity :record_mte_catalog_number
      upsert_fields [:extra_data | DarwinCore.Schema.prefixed_attribute_names()]

      change SetMandatoryAttributes
      change Validation.Changes.SetOptionalAttributes

      change manage_relationship(:record, type: :append)
      change manage_relationship(:collection, type: :append)
    end

    create :validate do
      description """
      Creates or updates a `ValidatedRecord` from the given `params`.

      The record is associated with the given `DataAggregator.Records.Validation`
      """

      argument :record, :struct, allow_nil?: true
      argument :collection, :struct, allow_nil?: true

      change SetMandatoryAttributes
      change Validation.Changes.UpdateRawRecordStateAfterAction

      upsert? true
      upsert_identity :record_mte_catalog_number
      upsert_fields [:extra_data | DarwinCore.Schema.prefixed_attribute_names()]

      change manage_relationship(:record, type: :append)
      change manage_relationship(:collection, type: :append)
    end

    action :bulk_validate, :map do
      description """
      Validates multiple records using `Ash.bulk_create/3`.

      The `rows` can be any enumberable, where each item which will be used as `params` for
      the `DataAggregator.Records.ValidatedRecord.validate/1` action.
      """

      argument :rows, :term, allow_nil?: false
      run Validation.Actions.BulkValidate
    end
  end

  identities do
    identity :record_mte_catalog_number, [:record_id, :mte_catalog_number]
  end

  code_interface do
    define :read
    define :create
    define :update
    define :destroy
    define :bulk_validate, args: [:rows]
    define :validate
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_record, action: :read, get_by: [:record_id]
  end

  postgres do
    table "validated_records"
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

  json_api do
    type "validated_records"

    routes do
      base "/datasets/:collection_id/validated_records"

      primary_key do
        keys [:id]
      end

      get :read
      index :read
      patch :update
      delete :destroy
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
