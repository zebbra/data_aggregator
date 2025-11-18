defmodule DataAggregator.Records.Record.Image do
  @moduledoc """
  Resource representing an image attached to a `DataAggregator.Records.Record`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Image.Changes

  attributes do
    uuid_attribute :id, prefix: "img", public?: true
    attribute :size, :integer, public?: true
    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment, public?: true
    belongs_to :record, Record, public?: true
    belongs_to :image_upload, ImageUpload, public?: true

    belongs_to :collection, Collection do
      primary_key? true
      public? true
      allow_nil? false
    end
  end

  calculations do
    calculate :image_url, :string, Record.Calculations.ImageUrl
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update]

    destroy :destroy do
      primary? true
      require_atomic? false

      change Changes.RemoveAssociatedMedia
      change cascade_destroy(:attachment)
    end
  end

  code_interface do
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "record_images"
    repo DataAggregator.Repo

    references do
      reference :attachment, on_delete: :delete, on_update: :update, index?: true
      reference :image_upload, on_delete: :delete, on_update: :update, index?: true
      reference :collection, on_delete: :delete, on_update: :update

      reference :record,
        on_delete: :delete,
        on_update: :update,
        index?: true,
        match_with: [collection_id: :collection_id]
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
