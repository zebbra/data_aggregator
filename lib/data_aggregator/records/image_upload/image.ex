defmodule DataAggregator.Records.ImageUpload.Image do
  @moduledoc """
  Resource representing an image uploaded by a `DataAggregator.Records.ImageUpload`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.ImageUpload

  attributes do
    uuid_attribute :id, prefix: "img", public?: true
    attribute :size, :integer, public?: true
    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment, public?: true
    belongs_to :image_upload, ImageUpload, public?: true
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "image_upload_images"
    repo DataAggregator.Repo

    references do
      reference :image_upload, on_delete: :delete, on_update: :update, index?: true
      reference :attachment, on_delete: :delete, on_update: :update, index?: true
    end
  end

  json_api do
    type "image_upload_image"

    routes do
      base "/image_upload_images"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
