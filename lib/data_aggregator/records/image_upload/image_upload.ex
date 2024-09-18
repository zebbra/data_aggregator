defmodule DataAggregator.Records.ImageUpload do
  @moduledoc """
  Resource for image uploads from a file. Updating image urls of records in the collection
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ImageUpload

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

    has_many :images, ImageUpload.Image, public?: true

    many_to_many :image_attachments, Attachment do
      through ImageUpload.Image
      source_attribute_on_join_resource :image_upload_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
      public? true
    end
  end

  actions do
    default_accept :*
    defaults [:destroy, :update]

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

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :by_collection, args: [:collection_id]
    define :create, args: [:collection]
    define :create_from_path, args: [:collection, :path]
    define :destroy
  end

  postgres do
    table "image_uploads"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update, index?: true
    end
  end
end
