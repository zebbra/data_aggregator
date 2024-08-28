defmodule DataAggregator.Records.Record do
  @moduledoc """
  Ash resource representing a record.

  > #### Info {: .info}
  >
  > All Darwin Core attributes are defined in `DataAggregator.DarwinCore.Schema` and included
  > by the `DataAggregator.DarwinCore.Resource` extension.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [
      AshUUID,
      AshJsonApi.Resource,
      DataAggregator.DarwinCore.Resource,
      AshStateMachine,
      AshPaperTrail.Resource
    ],
    notifiers: [Ash.Notifier.PubSub]

  use AshPagify.Tsearch

  alias __MODULE__
  alias DataAggregator.DarwinCore
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.ApprovalStatusType
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.PublicationStatusType
  alias DataAggregator.Records.Record.Calculations.IucnRedlist
  alias DataAggregator.Records.Record.Calculations.Mids
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies
  alias Record.Changes.CreateEncodedRecordAfterAction
  alias Record.Changes.SetBasisOfRecord
  alias Record.Changes.SetImportedAfterAction
  alias Record.Changes.SetOccurrenceID

  require Ash.Expr
  require Ash.Query

  @type t :: %Record{}

  @ash_pagify_scopes %{
    status: [
      %{name: :all, filter: nil, default?: true},
      %{
        name: :not_encoded,
        filter: %{state: %{not_equals: :encoded}}
      }
    ]
  }
  def ash_pagify_scopes, do: @ash_pagify_scopes

  @full_text_search [
    tsvector_column: [
      encoded_tsvector: Ash.Expr.expr(encoded_tsvector)
    ]
  ]
  def full_text_search, do: @full_text_search

  attributes do
    uuid_attribute :id, prefix: "rec", public?: true
    attribute :import_data, :map, public?: true
    attribute :extra_data, :map, public?: true
    attribute :errors, :map, public?: true

    attribute :fast_track_status, PublicationStatusType,
      allow_nil?: false,
      default: :not_published,
      public?: true

    attribute :approval_status, ApprovalStatusType,
      allow_nil?: false,
      default: :not_approved,
      public?: true

    attribute :iucn_redlist_category, :string, allow_nil?: true, public?: true

    attribute :last_approval_started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :last_imported_at, :utc_datetime, allow_nil?: true, public?: true

    attribute :tsv, :string, allow_nil?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
      public? true
    end

    many_to_many :imports, Import do
      through Import.Record
      public? true
    end

    has_many :images, Record.Image, public?: true

    many_to_many :image_attachments, Attachment do
      through Record.Image
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
      public? true
    end

    has_one :encoded_record, EncodedRecord do
      allow_nil? true
      public? true
    end

    belongs_to :swiss_species, SwissSpecies do
      source_attribute :tax_taxon_id
      destination_attribute :usage_key

      allow_nil? true
      attribute_type :integer
      define_attribute? false
      public? true
    end
  end

  calculations do
    calculate :iucn_redlist,
              :boolean,
              IucnRedlist,
              public?: true

    calculate :encoded,
              :boolean,
              expr(state == :encoded)

    calculate :mids_level,
              :integer,
              expr(
                cond do
                  mids_level_four -> 4
                  mids_level_three -> 3
                  mids_level_two -> 2
                  mids_level_one -> 1
                  true -> 0
                end
              ),
              public?: true

    calculate :mids_level_one,
              :boolean,
              Mids.LevelOne

    calculate :mids_level_two,
              :boolean,
              Mids.LevelTwo

    calculate :mids_level_three,
              :boolean,
              Mids.LevelThree

    calculate :mids_level_four,
              :boolean,
              Mids.LevelFour

    calculate :tsvector, AshPostgres.Tsvector, expr(tsv)

    calculate :encoded_tsvector, AshPostgres.Tsvector, expr(encoded_record.tsv)
  end

  paper_trail do
    change_tracking_mode :changes_only
    store_action_name? true

    ignore_attributes [
      :inserted_at,
      :updated_at,
      :import_data,
      :errors,
      :approval_status,
      :fast_track_status,
      :state
    ]

    attributes_as_attributes [:mte_catalog_number, :tax_scientific_name]
    reference_source? false

    mixin DataAggregator.Records.RecordVersionMixin
    version_extensions extensions: [AshJsonApi.Resource]
  end

  state_machine do
    initial_states [:imported]
    default_initial_state :imported

    transitions do
      transition :set_imported, from: [:encoded, :failed, :encoding, :imported], to: :imported

      transition :enqueue_encoder,
        from: [:imported, :encoded, :failed, :encoding],
        to: :queued

      transition :set_encoding,
        from: [:queued, :imported, :failed, :encoded],
        to: :encoding

      transition :set_encoded, from: :encoding, to: :encoded
      transition :set_encoding_failed, from: :encoding, to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:update]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 countable: true,
                 required?: false,
                 keyset?: true
    end

    read :by_collection do
      argument :collection_id, :string, allow_nil?: false
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 countable: true,
                 required?: false,
                 keyset?: true

      filter expr(collection_id == ^arg(:collection_id))
    end

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false

      change Record.Changes.SetGrSciCollInstitution
      change SetOccurrenceID
      change SetBasisOfRecord
      change SetImportedAfterAction
      change CreateEncodedRecordAfterAction

      change manage_relationship(:collection, :collection, type: :append)
    end

    create :import do
      description """
      Creates or updates a `Record` from the given `params`.

      The record is associated with the give `DataAggregator.Records.Import` and
      its `DataAggregator.Records.Collection`.
      """

      argument :import, :struct, allow_nil?: false
      argument :params, :map, allow_nil?: false
      change Record.Changes.RelateImport
      change Record.Changes.RelateCollectionFromImport
      change Record.Changes.ExtractAttributes
      change SetOccurrenceID
      change SetBasisOfRecord
      change Record.Changes.SetPublicationStale
      change SetImportedAfterAction
      change CreateEncodedRecordAfterAction

      upsert? true
      upsert_identity :collection_mte_catalog_number
      upsert_fields [:import_data, :extra_data | DarwinCore.Schema.prefixed_attribute_names()]
    end

    update :enqueue_encoder do
      accept []
      require_atomic? false

      change transition_state(:queued)
      change Record.Changes.EnqueueEncoder
    end

    update :enqueue_fast_track_checker do
      accept []
      require_atomic? false

      change Record.Changes.EnqueueFastTrackChecker
    end

    action :bulk_import, :map do
      description """
      Imports multiple records using `Ash.bulk_create/3`.

      The `rows` can be any enumberable, where each item which will be used as `params` for
      the `DataAggregator.Records.Record.import/2` action.
      """

      argument :import, :struct, allow_nil?: false
      argument :rows, :term, allow_nil?: false

      run Record.Actions.BulkImport
    end

    action :encode, :map do
      argument :record, :term, allow_nil?: false
      argument :catalog, :atom, allow_nil?: false

      run Encoding.Actions.EncodeRecord
    end

    update :check_if_fast_track_pubished do
      require_atomic? false

      change Record.Changes.CheckIfFastTrackPublished
    end

    update :set_imported do
      require_atomic? false

      change transition_state(:imported)
      change set_attribute(:last_imported_at, &DateTime.utc_now/0)
    end

    update :set_encoding do
      require_atomic? false

      change transition_state(:encoding)
    end

    update :set_encoded do
      require_atomic? false

      change transition_state(:encoded)
    end

    update :set_encoding_failed do
      require_atomic? false

      change transition_state(:failed)
    end

    update :update_fast_track_status do
      argument :status, :atom, allow_nil?: false
      require_atomic? false

      change set_attribute(:fast_track_status, expr(^arg(:status)))
    end

    update :update_approval_status do
      argument :status, :atom, allow_nil?: false
      require_atomic? false

      change set_attribute(:approval_status, expr(^arg(:status)))
    end

    update :update_last_approval_started_at do
      accept []
      require_atomic? false

      change set_attribute(:last_approval_started_at, &DateTime.utc_now/0)
    end

    destroy :destroy do
      primary? true
      require_atomic? false

      change Record.Changes.DestroyVersions
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "record"

    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
  end

  identities do
    identity :collection_mte_catalog_number, [:collection_id, :mte_catalog_number]
  end

  code_interface do
    define :read
    define :by_collection, args: [:collection_id]
    define :create
    define :import, args: [:import, :params]
    define :bulk_import, args: [:import, :rows]
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_mte_catalog_number, action: :read, get_by: [:mte_catalog_number]
    define :encode, args: [:record, :catalog]
    define :set_imported
    define :set_encoding
    define :set_encoded
    define :set_encoding_failed
    define :enqueue_encoder
    define :update_fast_track_status, args: [:status]
    define :update_approval_status, args: [:status]
    define :check_if_fast_track_pubished
    define :enqueue_fast_track_checker
    define :update_last_approval_started_at
  end

  policies do
    policy always() do
      authorize_if always()
      # authorize_if DataAggregator.Checks.IsAdmin
      # authorize_if relates_to_institution_filter([:collection], :grscicoll_institution_key)
    end
  end

  postgres do
    table "records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
    end
  end

  json_api do
    type "records"

    routes do
      base "/records"

      get :read
      index :read
      patch :update
      delete :destroy
    end
  end
end
