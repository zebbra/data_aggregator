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
    api: DataAggregator.Records,
    extensions: [
      AshUUID,
      AshGraphql.Resource,
      AshJsonApi.Resource,
      DataAggregator.DarwinCore.Resource,
      AshPaperTrail.Resource
    ]

  alias __MODULE__
  alias DataAggregator.DarwinCore
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Record

  @type t :: %EncodedRecord{}

  attributes do
    uuid_attribute :id, prefix: "enr"
    attribute :extra_data, :map
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :record, Record do
      allow_nil? false
    end
  end

  paper_trail do
    change_tracking_mode :changes_only
    store_action_name? true
    ignore_attributes [:inserted_at, :updated_at]
    reference_source? false

    mixin DataAggregator.Records.EncodedRecordVersionMixin
    version_extensions extensions: [AshJsonApi.Resource]
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
      pagination offset?: true, countable: true, required?: false
    end

    create :create do
      primary? true
      argument :record, Record, allow_nil?: false

      upsert? true
      upsert_fields [:extra_data | DarwinCore.Schema.prefixed_attribute_names()]
      upsert_identity :record_mte_catalog_number

      change Encoding.Changes.SetMandatoryAttributes
      change Encoding.Changes.SetOptionalAttributes
      change manage_relationship(:record, :record, type: :append)
    end
  end

  identities do
    identity :record_mte_catalog_number, [:record_id, :mte_catalog_number]
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_record, action: :read, get_by: [:record]
  end

  postgres do
    table "encoded_records"
    repo DataAggregator.Repo

    references do
      reference :record, on_delete: :delete, on_update: :update
    end
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
      keys [:id]
    end

    routes do
      base "/encoded_records"

      get :read
      index :read
      patch :update
      delete :destroy
    end
  end
end
