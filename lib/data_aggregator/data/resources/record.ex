defmodule DataAggregator.Data.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Platform.Collection
  alias DataAggregator.Storage.Attachment

  attributes do
    uuid_attribute :id, prefix: "rec"

    attribute :unique_qualifier, :string do
      allow_nil? false
    end

    attribute :import_data, :map
    attribute :meta_data, :map

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      api DataAggregator.Platform
    end

    many_to_many :images, Attachment do
      api DataAggregator.Storage
      through DataAggregator.Data.RecordImage
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :attachment_id
    end

    has_many :images_join_assoc, DataAggregator.Data.RecordImage
  end

  actions do
    defaults [:create, :update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
    end
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
    table "records"
    repo DataAggregator.Repo
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  graphql do
    type :record

    queries do
      get :get_record, :read
      list :list_records, :read
    end

    mutations do
      create :create_record, :create
      update :update_record, :update
      destroy :destroy_record, :destroy
    end
  end

  json_api do
    type "records"

    routes do
      base("/records")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
