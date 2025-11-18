defmodule DataAggregator.Records.ImageUpload do
  @moduledoc """
  Resource for image uploads from a file. Updating image urls of records in the collection
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Accounts.User
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Calculations
  alias DataAggregator.Records.ImageUpload.Changes
  alias DataAggregator.Records.Record

  @type t :: %ImageUpload{}

  attributes do
    uuid_attribute :id, prefix: "iuf", public?: true

    timestamps public?: true, writable?: false

    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true

    attribute :invalid_file_infos, {:array, :map}, allow_nil?: true, public?: true

    attribute :mapped_images_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :unmapped_images_count, :integer, allow_nil?: false, default: 0, public?: true

    attribute :max_mapping_operations_count, :integer,
      allow_nil?: false,
      default: 0,
      public?: true

    attribute :current_mapping_operations_count, :integer,
      allow_nil?: false,
      default: 0,
      public?: true

    attribute :error_message, :string, allow_nil?: true, default: nil, public?: true

    attribute :invalid_files_count, :integer, allow_nil?: false, default: 0, public?: true

    attribute :mapping_identifier, :atom,
      allow_nil?: false,
      default: :mte_catalog_number,
      public?: true
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
      public? true
    end

    belongs_to :created_by, User, public?: true
    belongs_to :started_by, User, public?: true
    belongs_to :attachment, Attachment, public?: true
    belongs_to :upload_log, Attachment, public?: true

    has_many :images, Record.Image, public?: true

    many_to_many :image_attachments, Attachment do
      through Record.Image
      source_attribute_on_join_resource :image_upload_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
      public? true
    end
  end

  calculations do
    calculate :mapped_images, {:array, :string}, Calculations.MappedImages
    calculate :unmapped_images, {:array, :string}, Calculations.UnmappedImages

    calculate :mapping_progress,
              :float,
              expr(
                if max_mapping_operations_count == 0,
                  do: 0,
                  else: current_mapping_operations_count / max_mapping_operations_count
              ),
              public?: true
  end

  state_machine do
    initial_states [:new]
    default_initial_state :new

    transitions do
      transition :enqueue_extraction, from: [:new], to: :extraction_queued
      transition :extract, from: [:extraction_queued, :new], to: :extracting
      transition :extract, from: [:extracting], to: :extracted

      transition :enqueue_mapping,
        from: [:extracted, :mapped, :mapping_failed, :mapping_incomplete],
        to: :mapping_queued

      transition :map, from: [:mapping_queued, :extracted], to: :mapping
      transition :map, from: :mapping, to: :mapped

      transition :set_extracting, from: [:extraction_queued, :new], to: :extracting
      transition :set_extracted, from: :extracting, to: :extracted

      transition :set_extraction_failed,
        from: [:extraction_queued, :extracting],
        to: :extraction_failed

      transition :set_mapping, from: [:mapping_queued, :extracted], to: :mapping
      transition :set_mapped, from: :mapping, to: :mapped
      transition :set_mapping_incomplete, from: [:mapping, :mapped], to: :mapping_incomplete
      transition :set_mapping_failed, from: [:mapping_queued, :mapping], to: :mapping_failed

      transition :cancel_mapping, from: [:mapping, :mapping_queued], to: :mapping_failed
    end
  end

  actions do
    default_accept :*
    defaults [:read, :update]

    update :update_mapping_identifier do
      accept [:mapping_identifier]
      require_atomic? false
    end

    update :enqueue_extraction do
      accept []
      require_atomic? false

      change transition_state(:extraction_queued)
      change Changes.EnqueueExtractor
    end

    update :add_mapping_progress do
      accept []
      argument :mapped, :integer, allow_nil?: false

      require_atomic? false

      change atomic_update(:mapped_images_count, expr(mapped_images_count + ^arg(:mapped)))
      change ensure_selected(:mapped_images_count)

      change atomic_update(:unmapped_images_count, expr(unmapped_images_count - ^arg(:mapped)))
      change ensure_selected(:unmapped_images_count)
    end

    update :add_current_mapping_operations_count do
      accept []
      argument :operations_count, :integer, allow_nil?: false

      require_atomic? false

      change atomic_update(
               :current_mapping_operations_count,
               expr(current_mapping_operations_count + ^arg(:operations_count))
             )

      change ensure_selected(:current_mapping_operations_count)
    end

    update :extract do
      accept []
      require_atomic? false

      change Changes.SetTimeout
      change Changes.SetExtractingBeforeTransaction
      change Changes.ExtractImages
      change Changes.SetExtractedAfterAction
      change Changes.SetExtractionFailedOnError
    end

    update :set_extracting do
      accept []
      require_atomic? false

      change transition_state(:extracting)
    end

    update :set_extracted do
      accept []
      require_atomic? false

      change transition_state(:extracted)
    end

    update :set_extraction_failed do
      accept []
      require_atomic? false

      change transition_state(:extraction_failed)
    end

    update :enqueue_mapping do
      accept [:started_by_id]
      require_atomic? false

      change Changes.SetCollectionMappingBeforeTransaction
      change transition_state(:mapping_queued)
      change Changes.EnqueueMapper
    end

    update :map do
      accept []
      require_atomic? false

      change Changes.SetTimeout
      change Changes.SetMappingBeforeTransaction
      change Changes.ResetCountBeforeTransaction
      change Changes.ResetErrorMsgBeforeTransaction
      change Changes.MapImages
      change Changes.SetMappedAfterAction
      change Changes.CreateUploadLogAfterAction
      change Changes.SetMappingIncompleteOnIncomplete
      change Changes.SetMappingFailedOnError
    end

    update :set_mapping do
      accept []
      require_atomic? false

      change set_attribute(:started_at, &DateTime.utc_now/0)
      change transition_state(:mapping)
    end

    update :set_mapped do
      accept []
      require_atomic? false

      change transition_state(:mapped)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :set_mapping_incomplete do
      accept []
      require_atomic? false

      change transition_state(:mapping_incomplete)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :set_mapping_failed do
      accept []
      require_atomic? false

      change transition_state(:mapping_failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :set_error_message do
      accept []
      argument :error_message, :string, allow_nil?: true

      require_atomic? false

      change set_attribute(:error_message, expr(^arg(:error_message)))
    end

    update :cancel_mapping do
      accept []
      require_atomic? false

      change transition_state(:mapping_failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end

    update :update_upload_log do
      accept []
      argument :upload_log, :struct, allow_nil?: false
      require_atomic? false

      change manage_relationship(:upload_log, type: :append)
      change load(:upload_log)
    end

    read :active do
      filter expr(state in [:mapping, :mapping_queued])
    end

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false
      change manage_relationship(:collection, type: :append)
    end

    create :create_from_path do
      accept [:created_by_id]
      argument :collection, :struct, allow_nil?: false
      argument :path, :string, allow_nil?: false
      argument :filename, :string, allow_nil?: true
      change manage_relationship(:collection, type: :append)
      change Changes.ValidateFile
      change Changes.CreateAttachment
    end

    destroy :destroy do
      accept []

      primary? true
      require_atomic? false

      change Changes.DeleteAllMedia
      change cascade_destroy(:attachment)
      change cascade_destroy(:upload_log)
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "image_upload"

    publish_all :create, [[:_tenant], "created"]
    publish_all :destroy, [[:_tenant], "destroyed", [:id, nil]]
    publish :set_extracting, [[:_tenant], "updated", [:id, nil]]
    publish :set_extracted, [[:_tenant], "updated", [:id, nil]]
    publish :set_extraction_failed, [[:_tenant], "updated", [:id, nil]]
    publish :set_mapping, [[:_tenant], "updated", [:id, nil]]
    publish :set_mapped, [[:_tenant], "updated", [:id, nil]]
    publish :set_mapping_incomplete, [[:_tenant], "updated", [:id, nil]]
    publish :set_mapping_failed, [[:_tenant], "updated", [:id, nil]]
    publish :add_mapping_progress, [[:_tenant], "updated", [:id, nil]]
  end

  code_interface do
    define :read
    define :update
    define :get_by_id, action: :read, get_by: [:id]
    define :active
    define :create, args: [:collection]
    define :create_from_path, args: [:collection, :path]
    define :destroy
    define :set_extracting
    define :set_extracted
    define :set_extraction_failed
    define :set_mapping
    define :set_mapped
    define :set_mapping_incomplete
    define :set_mapping_failed
    define :set_error_message, args: [:error_message]
    define :enqueue_extraction
    define :extract
    define :update_mapping_identifier, args: [:mapping_identifier]
    define :enqueue_mapping
    define :map
    define :cancel_mapping
    define :update_upload_log, args: [:upload_log]
    define :add_mapping_progress, args: [:mapped]
    define :add_current_mapping_operations_count, args: [:operations_count]
  end

  postgres do
    table "image_uploads"
    repo DataAggregator.Repo

    references do
      reference :collection,
        on_delete: :nothing,
        on_update: :update,
        index?: true,
        deferrable: true
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
