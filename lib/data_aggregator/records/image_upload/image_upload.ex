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
  alias DataAggregator.Records.ImageUpload.Changes.SetTimeout
  alias DataAggregator.Records.Record

  @type t :: %ImageUpload{}

  attributes do
    uuid_attribute :id, prefix: "iuf", public?: true

    timestamps public?: true, writable?: false

    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true

    attribute :invalid_file_infos, {:array, :map}, allow_nil?: true, public?: true

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
    calculate :mapped_images, {:array, :string}, ImageUpload.Calculations.MappedImages
    calculate :unmapped_images, {:array, :string}, ImageUpload.Calculations.UnmappedImages
    calculate :mapped_images_count, :integer, expr(length(mapped_images))
    calculate :unmapped_images_count, :integer, expr(length(unmapped_images))
    calculate :invalid_files_count, :integer, expr(length(invalid_file_infos))
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
    defaults [:read, :destroy, :update]

    update :update_mapping_identifier do
      accept [:mapping_identifier]
      require_atomic? false
    end

    update :enqueue_extraction do
      accept []
      require_atomic? false

      change transition_state(:extraction_queued)
      change ImageUpload.Changes.EnqueueExtractor
    end

    update :extract do
      accept []
      require_atomic? false

      change SetTimeout
      change ImageUpload.Changes.SetExtractingBeforeTransaction
      change ImageUpload.Changes.ExtractImages
      change ImageUpload.Changes.SetExtractedAfterAction
      change ImageUpload.Changes.SetExtractionFailedOnError
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

      change ImageUpload.Changes.SetCollectionMappingBeforeTransaction
      change transition_state(:mapping_queued)
      change ImageUpload.Changes.EnqueueMapper
    end

    update :map do
      accept []
      require_atomic? false

      change SetTimeout
      change ImageUpload.Changes.SetMappingBeforeTransaction
      change ImageUpload.Changes.MapImages
      change ImageUpload.Changes.SetMappedAfterAction
      change ImageUpload.Changes.CreateUploadLogAfterAction
      change ImageUpload.Changes.SetMappingIncompleteOnIncomplete
      change ImageUpload.Changes.SetMappingFailedOnError
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
      change ImageUpload.Changes.ValidateFile
      change ImageUpload.Changes.CreateAttachment
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "image_upload"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
    publish :set_extracting, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_extracted, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_extraction_failed, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_mapping, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_mapped, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_mapping_incomplete, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_mapping_failed, [[:collection_id, nil], "updated", [:id, nil]]
  end

  code_interface do
    define :read
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
    define :enqueue_extraction
    define :extract
    define :update_mapping_identifier, args: [:mapping_identifier]
    define :enqueue_mapping
    define :map
    define :cancel_mapping
    define :update_upload_log, args: [:upload_log]
  end

  postgres do
    table "image_uploads"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update, index?: true
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
