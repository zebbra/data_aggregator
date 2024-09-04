defmodule DataAggregator.Records.Record.Image do
  @moduledoc """
  Resource representing an image attached to a `DataAggregator.Records.Record`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Record

  attributes do
    uuid_attribute :id, prefix: "img", public?: true
    attribute :size, :integer, public?: true
    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment, public?: true
    belongs_to :record, Record, public?: true
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
    table "record_images"
    repo DataAggregator.Repo

    references do
      reference :record, on_delete: :delete, on_update: :update, index?: true
      reference :attachment, on_delete: :delete, on_update: :update, index?: true
    end
  end

  json_api do
    type "record_image"

    routes do
      base "/record_images"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
