defmodule DataAggregator.Records.ApprovedRecord do
  @moduledoc """
  Ash resource representing a approved_record.

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
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.Approval.Changes.SetMandatoryAttributes
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @type t :: %ApprovedRecord{}

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
      change Approval.Changes.SetOptionalAttributes

      change manage_relationship(:record, type: :append)
      change manage_relationship(:collection, type: :append)
    end

    create :approve do
      description """
      Creates or updates a `ApprovedRecord` from the given `params`.

      The record is associated with the given `DataAggregator.Records.Approval`
      """

      argument :record, :struct, allow_nil?: true
      argument :collection, :struct, allow_nil?: true

      change SetMandatoryAttributes
      change Approval.Changes.UpdateRawRecordStateAfterAction

      upsert? true
      upsert_identity :record_mte_catalog_number
      upsert_fields [:extra_data | DarwinCore.Schema.prefixed_attribute_names()]

      change manage_relationship(:record, type: :append)
      change manage_relationship(:collection, type: :append)
    end

    action :bulk_approve, :map do
      description """
      Approves multiple records using `Ash.bulk_create/3`.

      The `rows` can be any enumberable, where each item which will be used as `params` for
      the `DataAggregator.Records.ApprovedRecord.approve/1` action.
      """

      argument :rows, :term, allow_nil?: false
      run Approval.Actions.BulkApprove
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
    define :bulk_approve, args: [:rows]
    define :approve
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_record, action: :read, get_by: [:record_id]
  end

  postgres do
    table "approved_records"
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
    type "approved_record"

    primary_key do
      keys [:id, :collection_id]
    end

    routes do
      base "/approved_records"

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
