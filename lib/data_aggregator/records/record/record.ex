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
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.PublicationStatusType

  @type t :: %Record{}

  @default_limit 15
  def default_limit, do: @default_limit

  attributes do
    uuid_attribute :id, prefix: "rec"
    attribute :import_data, :map
    attribute :extra_data, :map
    attribute :errors, :map

    attribute :fast_track_status, PublicationStatusType,
      allow_nil?: false,
      default: :not_published

    attribute :approval_status, PublicationStatusType, allow_nil?: false, default: :not_published

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

    has_one :encoded_record, EncodedRecord do
      allow_nil? true
    end
  end

  calculations do
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
              expr(
                not is_nil(mte_catalog_number) and
                  not is_nil(tax_scientific_name) and
                  not is_nil(oth_institution_code)
              )

    calculate :mids_level_two,
              :boolean,
              expr(
                mids_level_one and
                  ((not is_nil(mte_part_of_organism) or
                      not is_nil(encoded_record.mte_part_of_organism)) and
                     (not is_nil(tax_taxon_id) or not is_nil(encoded_record.tax_taxon_id)))
              )

    calculate :mids_level_three,
              :boolean,
              expr(
                mids_level_two and
                  (not is_nil(collection.code) and
                     (not is_nil(eve_event_date) or not is_nil(encoded_record.eve_event_date)) and
                     (not is_nil(mte_recorded_by) or not is_nil(encoded_record.mte_recorded_by)) and
                     (not is_nil(idf_type_status) or not is_nil(encoded_record.idf_type_status)) and
                     (not is_nil(tax_original_name_usage) or
                        not is_nil(encoded_record.tax_original_name_usage)) and
                     (not is_nil(loc_continent) or not is_nil(encoded_record.loc_continent)) and
                     (not is_nil(loc_country) or not is_nil(encoded_record.loc_country)) and
                     (not is_nil(loc_county) or not is_nil(encoded_record.loc_county)) and
                     (not is_nil(loc_decimal_latitude) or
                        not is_nil(encoded_record.loc_decimal_latitude)) and
                     (not is_nil(loc_decimal_longitude) or
                        not is_nil(encoded_record.loc_decimal_longitude)) and
                     (not is_nil(loc_higher_geography) or
                        not is_nil(encoded_record.loc_higher_geography)) and
                     (not is_nil(loc_locality) or not is_nil(encoded_record.loc_locality)) and
                     (not is_nil(loc_state_province) or
                        not is_nil(encoded_record.loc_state_province)) and
                     (not is_nil(loc_verbatim_depth) or
                        not is_nil(encoded_record.loc_verbatim_depth)) and
                     (not is_nil(loc_verbatim_elevation) or
                        not is_nil(encoded_record.loc_verbatim_elevation)) and
                     (not is_nil(mte_year_collection_entrance) or
                        not is_nil(encoded_record.mte_year_collection_entrance)) and
                     (not is_nil(occ_occurrence_id) or
                        not is_nil(encoded_record.occ_occurrence_id)))
              )

    calculate :mids_level_four,
              :boolean,
              expr(
                mids_level_three and
                  (not is_nil(eve_verbatim_event_date) or
                     not is_nil(encoded_record.eve_verbatim_event_date) or
                     (not is_nil(idf_identified_by) or
                        not is_nil(encoded_record.idf_identified_by)) or
                     (not is_nil(idf_identification_qualifier) or
                        not is_nil(encoded_record.idf_identification_qualifier)) or
                     (not is_nil(idf_identification_verification_status) or
                        not is_nil(encoded_record.idf_identification_verification_status)) or
                     (not is_nil(idf_last_verified_by) or
                        not is_nil(encoded_record.idf_last_verified_by)) or
                     (not is_nil(idf_verbatim_identification) or
                        not is_nil(encoded_record.idf_verbatim_identification)) or
                     (not is_nil(loc_georeferenced_by) or
                        not is_nil(encoded_record.loc_georeferenced_by)) or
                     (not is_nil(loc_georeference_verification_status) or
                        not is_nil(encoded_record.loc_georeference_verification_status)) or
                     (not is_nil(loc_verbatim_coordinates) or
                        not is_nil(encoded_record.loc_verbatim_coordinates)) or
                     (not is_nil(loc_verbatim_latitude) or
                        not is_nil(encoded_record.loc_verbatim_latitude)) or
                     (not is_nil(loc_verbatim_longitude) or
                        not is_nil(encoded_record.loc_verbatim_longitude)) or
                     (not is_nil(loc_verbatim_locality) or
                        not is_nil(encoded_record.loc_verbatim_locality)) or
                     (not is_nil(mte_associated_media) or
                        not is_nil(encoded_record.mte_associated_media)) or
                     (not is_nil(mte_completeness) or not is_nil(encoded_record.mte_completeness)) or
                     (not is_nil(mte_other_catalog_numbers) or
                        not is_nil(encoded_record.mte_other_catalog_numbers)) or
                     (not is_nil(mte_verbatim_label) or
                        not is_nil(encoded_record.mte_verbatim_label)))
              )
  end

  paper_trail do
    change_tracking_mode :changes_only
    store_action_name? true
    ignore_attributes [:inserted_at, :updated_at]
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
        from: [:imported, :encoded, :failed, :iencoded, :encoding],
        to: :queued

      transition :set_encoding,
        from: [:queued, :imported, :failed, :encoded],
        to: :encoding

      transition :set_encoded, from: :encoding, to: :encoded
      transition :set_failed, from: :encoding, to: :failed
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
                 default_limit: @default_limit,
                 countable: true,
                 required?: false,
                 keyset?: true
    end

    create :create do
      primary? true
      argument :collection, Collection, allow_nil?: false

      change Record.Changes.SetImportedAfterAction
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
      change Record.Changes.SetPublicationStale
      change Record.Changes.SetImportedAfterAction

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

    update :set_imported do
      change transition_state(:imported)
    end

    update :set_encoding do
      change transition_state(:encoding)
    end

    update :set_encoded do
      change transition_state(:encoded)
    end

    update :set_failed do
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

    destroy :destroy do
      primary? true
      change Record.Changes.DestroyVersions
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "record"

    publish_all :create, [[:collection_id, nil], "created", [:id, nil]]
    publish_all :update, [[:collection_id, nil], "updated", [:id, nil]]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
  end

  identities do
    identity :collection_mte_catalog_number, [:collection_id, :mte_catalog_number]
  end

  code_interface do
    define_for DataAggregator.Records

    define :read
    define :create
    define :import, args: [:import, :params]
    define :bulk_import, args: [:import, :rows]
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :encode, args: [:record, :catalog]
    define :set_imported
    define :set_encoding
    define :set_encoded
    define :set_failed
    define :enqueue_encoder
    define :update_fast_track_status, action: :update_fast_track_status, args: [:status]
    define :update_approval_status, action: :update_approval_status, args: [:status]
  end

  postgres do
    table "records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
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
