defmodule DataAggregator.Data.RecordImage do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Data.Record
  alias DataAggregator.Files.Attachment

  attributes do
    uuid_attribute :id, prefix: "img"
    attribute :size, :integer
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    belongs_to :record, Record
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Data
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "record_images"
    repo DataAggregator.Repo
  end

  graphql do
    type :record_image

    queries do
      get :get_record_image, :read
      list :list_record_images, :read
    end

    mutations do
      create :create_record_image, :create
      update :update_record_image, :update
      destroy :destroy_record_image, :destroy
    end
  end

  json_api do
    type "record_image"

    routes do
      base("/record_images")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
