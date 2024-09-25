defmodule DataAggregator.Records.ImageUpload do
  @moduledoc """
  Resource for image uploads from a file. Updating image urls of records in the collection
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Changes.SetTimeout
  alias DataAggregator.Records.Record

  @type t :: %ImageUpload{}

  attributes do
    uuid_attribute :id, prefix: "iuf", public?: true

    timestamps public?: true, writable?: false

    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true

    attribute :images_count, :integer, allow_nil?: true, public?: true
    attribute :images_mapped_count, :integer, allow_nil?: true, public?: true
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
      public? true
    end

    belongs_to :attachment, Attachment, public?: true

    has_many :images, Record.Image, public?: true

    many_to_many :image_attachments, Attachment do
      through Record.Image
      source_attribute_on_join_resource :image_upload_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
      public? true
    end
  end

  state_machine do
    initial_states [:new]
    default_initial_state :new

    transitions do
      transition :enqueue_extraction, from: [:new], to: :extraction_queued
      transition :extract, from: [:extraction_queued], to: :extracting
      transition :extract, from: [:extracting], to: :extracted

      transition :enqueue_mapping, from: :extracted, to: :mapping_queued
      transition :map, from: :mapping_queued, to: :mapping
      transition :map, from: :mapping, to: :mapped

      transition :set_extracting, from: :extraction_queued, to: :extracting
      transition :set_extracted, from: :extracting, to: :extracted

      transition :set_extraction_failed,
        from: [:extraction_queued, :extracting],
        to: :extraction_failed

      transition :set_mapping, from: :mapping_queued, to: :mapping
      transition :set_mapped, from: :mapping, to: :mapped
      transition :set_mapping_failed, from: [:mapping_queued, :mapping], to: :mapping_failed
    end
  end

  actions do
    default_accept :*
    defaults [:destroy, :update]

    update :enqueue_extraction do
      accept []
      require_atomic? false

      # change ImageUpload.Changes.SetCollectionExtractingBeforeTransaction
      change transition_state(:extraction_queued)
      change ImageUpload.Changes.EnqueueExtractor
    end

    update :extract do
      accept []
      require_atomic? false

      change SetTimeout
      change ImageUpload.Changes.SetExtractingBeforeTransaction
      change ImageUpload.Changes.ExtractImages
      # change ImageUpload.Changes.ValidateImages
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
      accept []
      require_atomic? false

      # change ImageUpload.Changes.SetCollectionMappingBeforeTransaction
      change transition_state(:mapping_queued)
      # change ImageUpload.Changes.EnqueueMapper
    end

    update :map do
      accept []
      require_atomic? false

      change SetTimeout
      change ImageUpload.Changes.SetMappingBeforeTransaction
      # change ImageUpload.Changes.MapImages
      change ImageUpload.Changes.SetMappedAfterAction
      # change ImageUpload.Changes.SetFailedOnError
    end

    update :set_mapping do
      accept []
      require_atomic? false

      change transition_state(:mapping)
    end

    update :set_mapped do
      accept []
      require_atomic? false

      change transition_state(:mapped)
    end

    update :set_mapping_failed do
      accept []
      require_atomic? false

      change transition_state(:mapping_failed)
    end

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
      change manage_relationship(:collection, :collection, type: :append)
    end

    create :create_from_path do
      accept []
      argument :collection, :struct, allow_nil?: false
      argument :path, :string, allow_nil?: false
      argument :filename, :string, allow_nil?: true
      change manage_relationship(:collection, :collection, type: :append)
      change ImageUpload.Changes.DetectFiles
      change ImageUpload.Changes.CreateAttachment
      # change ImageUpload.Changes.DetectColumns
      # change ImageUpload.Changes.CountRows
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
  end

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :by_collection, args: [:collection_id]
    define :create, args: [:collection]
    define :create_from_path, args: [:collection, :path]
    define :destroy
    define :set_extracting
    define :set_extracted
    define :set_extraction_failed
    define :set_mapping
    define :set_mapped
    define :set_mapping_failed
    define :enqueue_extraction
    define :extract
  end

  postgres do
    table "image_uploads"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update, index?: true
    end
  end

  json_api do
    type "image_upload"

    routes do
      base "/image_uploads"

      get :read
      index :read
      post :create_from_path
    end
  end
end
