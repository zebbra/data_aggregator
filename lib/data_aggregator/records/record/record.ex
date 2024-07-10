defmodule DataAggregator.Records.Record do
  @moduledoc """
  Ash resource representing a record.

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
      AshStateMachine,
      AshPaperTrail.Resource
    ],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.DarwinCore
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.ApprovalStatusType
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.PublicationStatusType
  alias DataAggregator.Records.Record.Calculations.Mids
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  @type t :: %Record{}

  @iucn_redlist_categories ["EX", "EW", "RE", "CR(PE)", "CR", "EN"]

  @pagify_scopes %{
    status: [
      %{name: :all, filter: nil, default?: true},
      %{
        name: :not_encoded,
        filter: %{
          or: [
            %{state: :imported},
            %{state: :queued},
            %{state: :encoding},
            %{state: :failed}
          ]
        }
      }
    ]
  }
  def pagify_scopes, do: @pagify_scopes

  attributes do
    uuid_attribute :id, prefix: "rec"
    attribute :import_data, :map
    attribute :extra_data, :map
    attribute :errors, :map

    attribute :fast_track_status, PublicationStatusType,
      allow_nil?: false,
      default: :not_published

    attribute :approval_status, ApprovalStatusType, allow_nil?: false, default: :not_approved
    attribute :iucn_redlist_category, :string, allow_nil?: true

    attribute :last_approval_started_at, :utc_datetime, allow_nil?: true
    attribute :last_imported_at, :utc_datetime, allow_nil?: true

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      api DataAggregator.Records
      allow_nil? false
    end

    many_to_many :imports, Import do
      api DataAggregator.Records
      through Import.Record
    end

    has_many :images, Record.Image

    many_to_many :image_attachments, Attachment do
      api DataAggregator.Files
      through Record.Image
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
    end

    belongs_to :encoder_job, Job do
      api DataAggregator.Jobs
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
    end

    belongs_to :fast_track_checker_job, Job do
      api DataAggregator.Jobs
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
    end

    has_one :encoded_record, EncodedRecord do
      allow_nil? true
    end

    belongs_to :swiss_species, SwissSpecies do
      api DataAggregator.Taxonomy

      source_attribute :tax_taxon_id
      destination_attribute :usage_key

      allow_nil? true
      attribute_writable? false
      attribute_type :integer
      define_attribute? false
    end
  end

  calculations do
    calculate :iucn_redlist,
              :boolean,
              expr(
                :iucn_redlist_category in @iucn_redlist_categories or
                  encoded_record.iucn_redlist_category in @iucn_redlist_categories
              )

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
              )

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
      argument :collection, Collection, allow_nil?: false

      change Record.Changes.SetGrSciCollInstitution
      change Record.Changes.SetOccurrenceID
      change Record.Changes.SetBasisOfRecord
      change Record.Changes.SetImportedAfterAction
      change Record.Changes.CreateEncodedRecordAfterAction

      change manage_relationship(:collection, :collection, type: :append)
    end

    create :import do
      description """
      Creates or updates a `Record` from the given `params`.

      The record is associated with the give `DataAggregator.Records.Import` and
      its `DataAggregator.Records.Collection`.
      """

      argument :import, Import, allow_nil?: false
      argument :params, :map, allow_nil?: false
      change Record.Changes.RelateImport
      change Record.Changes.RelateCollectionFromImport
      change Record.Changes.ExtractAttributes
      change Record.Changes.SetOccurrenceID
      change Record.Changes.SetBasisOfRecord
      change Record.Changes.SetPublicationStale
      change Record.Changes.SetImportedAfterAction
      change Record.Changes.CreateEncodedRecordAfterAction

      upsert? true
      upsert_identity :collection_mte_catalog_number
      upsert_fields [:import_data, :extra_data | DarwinCore.Schema.prefixed_attribute_names()]
    end

    update :enqueue_encoder do
      accept []
      change transition_state(:queued)
      change Record.Changes.EnqueueEncoder
      change load(:encoder_job)
    end

    update :enqueue_fast_track_checker do
      accept []
      change Record.Changes.EnqueueFastTrackChecker
      change load(:fast_track_checker_job)
    end

    action :bulk_import, :map do
      description """
      Imports multiple records using `DataAggregator.Records.bulk_create/3`.

      The `rows` can be any enumberable, where each item which will be used as `params` for
      the `DataAggregator.Records.Record.import/2` action.
      """

      argument :import, Import, allow_nil?: false
      argument :rows, :term, allow_nil?: false
      run Record.Actions.BulkImport
    end

    action :encode, :map do
      argument :record, :term, allow_nil?: false
      argument :catalog, :atom, allow_nil?: false

      run Encoding.Actions.EncodeRecord
    end

    update :check_if_fast_track_pubished do
      change Record.Changes.CheckIfFastTrackPublished
    end

    update :set_imported do
      change transition_state(:imported)
      change set_attribute(:last_imported_at, &DateTime.utc_now/0)
    end

    update :set_encoding do
      change transition_state(:encoding)
    end

    update :set_encoded do
      change transition_state(:encoded)
    end

    update :set_encoding_failed do
      change transition_state(:failed)
    end

    update :update_fast_track_status do
      argument :status, :atom, allow_nil?: false

      change set_attribute(:fast_track_status, expr(^arg(:status)))
    end

    update :update_approval_status do
      argument :status, :atom, allow_nil?: false

      change set_attribute(:approval_status, expr(^arg(:status)))
    end

    update :update_last_approval_started_at do
      accept []

      change set_attribute(:last_approval_started_at, &DateTime.utc_now/0)
    end

    destroy :destroy do
      primary? true
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
    define_for DataAggregator.Records

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

  postgres do
    table "records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
      reference :fast_track_checker_job, on_delete: :nilify, on_update: :update
    end
  end

  graphql do
    type :record

    queries do
      get :get_record, :read
      list :list_records, :read
    end

    mutations do
      update :update_record, :update
      destroy :destroy_record, :destroy
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
