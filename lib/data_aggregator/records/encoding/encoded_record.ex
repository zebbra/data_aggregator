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
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies
  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry

  @type t :: %EncodedRecord{}

  attributes do
    uuid_attribute :id, prefix: "enr", public?: true
    attribute :extra_data, :map, public?: true
    attribute :iucn_redlist_category, :string, allow_nil?: true, public?: true
    attribute :iucn_redlist, :boolean, writable?: false, public?: true
    attribute :mids_level_one, :boolean, writable?: false, public?: true
    attribute :mids_level_two, :boolean, writable?: false, public?: true
    attribute :mids_level_three, :boolean, writable?: false, public?: true
    attribute :mids_level_four, :boolean, writable?: false, public?: true

    attribute :tsv, :string, allow_nil?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :record, Record do
      allow_nil? false
      public? true
      filter expr(collection_id == parent(collection_id))
    end

    has_many :swiss_species, SwissSpecies do
      source_attribute :tax_taxon_id
      destination_attribute :usage_key
      public? true
    end

    has_one :swiss_species_registry, SwissSpeciesRegistry do
      source_attribute :tax_scientific_name
      destination_attribute :scientific_name
      public? true
    end

    belongs_to :collection, Collection do
      # We can't mark this as primary_key? true due to the limitations
      # of ash_paper_trail. In database schema (and also in the snapshots)
      # this is a primary key, so please make sure to account for this if
      # you change your model (most important in your migrations).
      allow_nil? false
      public? true
    end
  end

  paper_trail do
    change_tracking_mode :changes_only
    store_action_name? true

    ignore_attributes [:inserted_at, :updated_at]
    ignore_actions [:create, :destroy]

    attributes_as_attributes [:collection_id]
    reference_source? true

    mixin DataAggregator.Records.EncodedRecordVersionMixin
    version_extensions extensions: [AshJsonApi.Resource]

    belongs_to_actor :user, DataAggregator.Accounts.User,
      domain: DataAggregator.Accounts,
      define_attribute?: false,
      public?: true
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

      upsert? true

      upsert_fields [
                      :extra_data,
                      :iucn_redlist_category
                    ] ++ DarwinCore.Schema.prefixed_attribute_names()

      upsert_identity :record_mte_catalog_number

      change Encoding.Changes.SetMandatoryAttributes
      change Encoding.Changes.SetOptionalAttributes
    end

    update :update_return_minimal_fields do
      change Encoding.Changes.SelectMinimalFields
    end

    update :add_image_url do
      argument :image, :struct, allow_nil?: false
      require_atomic? false

      change Encoding.Changes.AddImageUrl
    end
  end

  identities do
    identity :record_mte_catalog_number, [:record_id, :mte_catalog_number]
    identity :by_collection, [:id, :collection_id]
  end

  code_interface do
    define :read
    define :create
    define :update
    define :update_return_minimal_fields
    define :add_image_url, args: [:image]
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_record, action: :read, get_by: [:record_id]
  end

  postgres do
    table "encoded_records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update

      reference :record,
        on_delete: :delete,
        on_update: :update,
        index?: true,
        match_with: [collection_id: :collection_id]
    end

    custom_indexes do
      index [:loc_continent, :tax_kingdom, :tax_phylum]
    end
  end

  json_api do
    type "encoded_records"

    routes do
      base "/datasets/:collection_id/encoded_records"

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
