defmodule DataAggregator.Storage.Attachment do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  attributes do
    uuid_attribute :id, prefix: "at"
    attribute :url, :string, allow_nil?: false
    attribute :meta_data, :map
    timestamps private?: false, writable?: false
  end

  relationships do
  end

  calculations do
    calculate :data, :map, DataAggregator.Storage.Calculations.Dataframe
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
    table "attachments"
    repo DataAggregator.Repo
  end

  graphql do
    type :attachment

    queries do
      get :get_attachment, :read
      list :list_attachments, :read
    end

    mutations do
      create :create_attachment, :create
      update :update_attachment, :update
      destroy :destroy_attachment, :destroy
    end
  end

  json_api do
    type "attachment"

    routes do
      base("/attachments")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
