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

  import DataAggregator.Checks.Custom

  alias __MODULE__
  alias DataAggregator.DarwinCore
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.PublicationStatusType
  alias DataAggregator.Records.Record.Calculations
  alias DataAggregator.Records.Record.Changes
  alias DataAggregator.Records.ValidationStatusType

  require Ash.Expr
  require Ash.Query

  @type t :: %Record{}

  @ash_pagify_options %{
    scopes: %{
      status: [
        %{name: :all, filter: nil, default?: true},
        %{
          name: :not_encoded,
          filter: %{state: %{not_equals: :encoded}}
        },
        %{
          name: :not_published,
          filter: %{fast_track_status: %{not_equals: :published}}
        },
        %{
          name: :not_validated,
          filter: %{validation_status: %{not_equals: :validated}}
        }
      ]
    },
    full_text_search: [
      tsvector_column: [
        encoded_tsvector: Ash.Expr.expr(encoded_tsvector)
      ]
    ]
  }

  def ash_pagify_options, do: @ash_pagify_options

  attributes do
    uuid_attribute :id, prefix: "rec", public?: true
    attribute :import_data, :map, public?: true
    attribute :extra_data, :map, public?: true
    attribute :errors, :map, public?: true

    attribute :fast_track_status, PublicationStatusType,
      allow_nil?: false,
      default: :not_published,
      public?: true

    attribute :validation_status, ValidationStatusType,
      allow_nil?: false,
      default: :not_validated,
      public?: true

    attribute :iucn_redlist_category, :string, allow_nil?: true, public?: true

    attribute :last_validation_started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :last_imported_at, :utc_datetime, allow_nil?: true, public?: true

    attribute :tsv, :string, allow_nil?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      # We can't mark this as primary_key? true due to the limitations
      # of ash_paper_trail. In database schema (and also in the snapshots)
      # this is a primary key, so please make sure to account for this if
      # you change your model (most important in your migrations).
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
      filter expr(collection_id == parent(collection_id))
    end
  end

  calculations do
    calculate :iucn_redlist,
              :boolean,
              expr(encoded_record.iucn_redlist),
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

    calculate :iucn_redlist_category_group, :string, Calculations.IucnRedlistCategoryGroup, public?: true

    calculate :loc_decimal_presence,
              :boolean,
              expr(
                not is_nil(encoded_record.loc_decimal_latitude) and
                  not is_nil(encoded_record.loc_decimal_longitude)
              ),
              public?: true

    calculate :loc_swiss_coordinates_95_presence,
              :boolean,
              expr(
                not is_nil(encoded_record.loc_swiss_coordinates_lv95_x) and
                  not is_nil(encoded_record.loc_swiss_coordinates_lv95_y)
              ),
              public?: true

    calculate :loc_swiss_coordinates_03_presence,
              :boolean,
              expr(
                not is_nil(encoded_record.loc_swiss_coordinates_lv03_x) and
                  not is_nil(encoded_record.loc_swiss_coordinates_lv03_y)
              ),
              public?: true

    calculate :mids_level_one,
              :boolean,
              expr(encoded_record.mids_level_one)

    calculate :mids_level_two,
              :boolean,
              expr(encoded_record.mids_level_two)

    calculate :mids_level_three,
              :boolean,
              expr(not is_nil(collection.code) and encoded_record.mids_level_three)

    calculate :mids_level_four,
              :boolean,
              expr(encoded_record.mids_level_four)

    calculate :tsvector, AshPostgres.Tsvector, expr(tsv)

    calculate :encoded_tsvector, AshPostgres.Tsvector, expr(encoded_record.tsv)

    calculate :eve_event_date_presence,
              :boolean,
              expr(not is_nil(encoded_record.eve_event_date)),
              public?: true

    calculate :not_encoded,
              :boolean,
              expr(
                state == :imported or
                  state == :queued or
                  state == :encoding or
                  state == :failed
              )

    calculate :not_published,
              :boolean,
              expr(fast_track_status != :published)

    calculate :not_validated,
              :boolean,
              expr(validation_status != :validated)

    calculate :changes, :map, Calculations.Changes do
      argument :transform?, :boolean, allow_nil?: true, default: false
      argument :escape_nil?, :boolean, allow_nil?: true, default: false
    end
  end

  paper_trail do
    change_tracking_mode :changes_only
    store_action_name? true

    ignore_attributes [
      :last_imported_at,
      :inserted_at,
      :updated_at,
      :import_data,
      :errors,
      :state
    ]

    ignore_actions [:destroy]
    on_actions [:update_fast_track_status, :update_validation_status]

    attributes_as_attributes [:mte_catalog_number, :tax_scientific_name, :collection_id]
    reference_source? true

    mixin DataAggregator.Records.RecordVersionMixin
    version_extensions extensions: [AshJsonApi.Resource]

    belongs_to_actor :user, DataAggregator.Accounts.User,
      domain: DataAggregator.Accounts,
      define_attribute?: false,
      public?: true
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
      transition :set_encoding_failed, from: [:encoding, :queued], to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read, :update]

    read :encoding do
      filter expr(state in [:encoding, :queued])
    end

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false

      change Changes.SetOccurrenceID
      change Changes.SetBasisOfRecord
      change Changes.CreateEncodedRecordAfterAction
      change set_attribute(:state, :imported)
      change set_attribute(:last_imported_at, &DateTime.utc_now/0)

      change manage_relationship(:collection, type: :append)
    end

    create :import do
      description """
      Creates or updates a `Record` from the given `params`.

      The record is associated with the give `DataAggregator.Records.Import` and
      its `DataAggregator.Records.Collection`.
      """

      argument :import, :struct, allow_nil?: false
      argument :params, :map, allow_nil?: false

      change Changes.RelateCollectionFromImport
      change Changes.ExtractAttributes
      change Changes.SetOccurrenceID
      change Changes.SetBasisOfRecord
      change Changes.RelateImport
      change Changes.SetPublicationStale
      change Changes.CreateEncodedRecordAfterAction
      change set_attribute(:state, :imported)
      change set_attribute(:last_imported_at, &DateTime.utc_now/0)

      upsert? true
      upsert_identity :collection_mte_catalog_number

      upsert_fields DarwinCore.Schema.prefixed_attribute_names() ++
                      [
                        :state,
                        :last_imported_at,
                        :import_data,
                        :extra_data
                      ]
    end

    update :enqueue_encoder do
      accept []
      require_atomic? false

      change transition_state(:queued)
      change Record.Changes.EnqueueEncoder
    end

    action :enqueue_fast_track_checker, :map do
      argument :published_record, :struct, allow_nil?: false

      run Record.Actions.EnqueueFastTrackChecker
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

      change Changes.CheckIfFastTrackPublished
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

    update :update_validation_status do
      argument :status, :atom, allow_nil?: false
      require_atomic? false

      change set_attribute(:validation_status, expr(^arg(:status)))
    end

    update :update_last_validation_started_at do
      accept []
      require_atomic? false

      change set_attribute(:last_validation_started_at, &DateTime.utc_now/0)
    end

    update :add_images do
      argument :images, {:array, :struct}, allow_nil?: false
      require_atomic? false

      change Changes.AddImages
    end

    destroy :destroy do
      primary? true
      require_atomic? false

      change Changes.DecrementCollectionRecordsCountAfterAction
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "record"

    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
  end

  identities do
    identity :collection_mte_catalog_number, [:collection_id, :mte_catalog_number]
    identity :by_collection, [:id, :collection_id]
  end

  code_interface do
    define :read
    define :encoding
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
    define :update_validation_status, args: [:status]
    define :check_if_fast_track_pubished
    define :enqueue_fast_track_checker, args: [:published_record]
    define :update_last_validation_started_at
    define :add_images, args: [:images]
  end

  policies do
    bypass with_role("admin") do
      authorize_if always()
    end

    bypass action([:bulk_import, :import, :encode, :enqueue_fast_track_checker]) do
      authorize_if always()
    end

    policy_group with_role(["collection_administrator", "data_digitizer"]) do
      policy action_type(:read) do
        authorize_if relates_to_institution_filter([:collection], :grscicoll_institution_key)
      end
    end

    policy_group with_role(["data_digitizer"]) do
      policy action_type([:create, :update, :destroy]) do
        authorize_if relates_to_institution_check([:collection], :grscicoll_institution_key)
      end
    end
  end

  postgres do
    table "records"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update
    end

    custom_indexes do
      index [:state, :validation_status, :fast_track_status], include: ["id"]
    end
  end

  json_api do
    type "records"

    routes do
      base "/datasets/:collection_id/records"

      get :read
      index :read
      patch :update
      post :create
      delete :destroy
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
