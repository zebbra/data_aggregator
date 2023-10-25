defmodule DataAggregator.Storage.Image do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Data.Record
  alias DataAggregator.Storage.Attachment

  attributes do
    uuid_attribute :id, prefix: "im"
    attribute :size, :integer
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment

    belongs_to :record, Record do
      api DataAggregator.Data
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Storage
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "images"
    repo DataAggregator.Repo
  end

  graphql do
    type :image

    queries do
      get :get_image, :read
      list :list_images, :read
    end

    mutations do
      create :create_image, :create
      update :update_image, :update
      destroy :destroy_image, :destroy
    end
  end

  json_api do
    type "image"

    routes do
      base("/images")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
