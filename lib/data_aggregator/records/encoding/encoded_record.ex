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
    domain: DataAggregator.Records,
    extensions: [
      AshUUID,
      AshJsonApi.Resource,
      DataAggregator.DarwinCore.Resource,
      AshPaperTrail.Resource
    ]

  alias __MODULE__
  alias DataAggregator.DarwinCore
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  @type t :: %EncodedRecord{}

  attributes do
    uuid_attribute :id, prefix: "enr", public?: true
    attribute :extra_data, :map, public?: true
    attribute :iucn_redlist_category, :string, allow_nil?: true, public?: true

    attribute :tsv, :string, allow_nil?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :record, Record do
      allow_nil? false
      public? true
    end

    has_many :swiss_species, SwissSpecies do
      source_attribute :tax_taxon_id
      destination_attribute :usage_key
      public? true
    end
  end

  paper_trail do
    change_tracking_mode :changes_only
    store_action_name? true

    ignore_attributes [:inserted_at, :updated_at]
    ignore_actions [:create]

    reference_source? true

    mixin DataAggregator.Records.EncodedRecordVersionMixin
    version_extensions extensions: [AshJsonApi.Resource]

    belongs_to_actor :user, DataAggregator.Accounts.User,
      domain: DataAggregator.Accounts,
      public?: true
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
      pagination offset?: true, countable: true, required?: false
    end

    create :create do
      primary? true
      argument :record, :struct, allow_nil?: false

      upsert? true

      upsert_fields [
                      :extra_data,
                      :iucn_redlist_category
                    ] ++ DarwinCore.Schema.prefixed_attribute_names()

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
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_record, action: :read, get_by: [:record_id]
  end

  postgres do
    table "encoded_records"
    repo DataAggregator.Repo

    references do
      reference :record, on_delete: :delete, on_update: :update, index?: true
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
