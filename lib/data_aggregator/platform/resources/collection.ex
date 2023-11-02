defmodule DataAggregator.Platform.Collection do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Platform.Institution

  attributes do
    uuid_attribute :id, prefix: "col"

    attribute :name, :string do
      allow_nil? false
    end

    # an iternationally valid code to identify the collection
    attribute :code, :string

    attribute :description, :string

    attribute :mapping, :map

    # allow sorting by inserted_at/updated_at
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :institution, Institution

    has_many :import_files, DataAggregator.Platform.ImportFile

    many_to_many :import_file_attachments, Attachment do
      api DataAggregator.Files
      through DataAggregator.Platform.ImportFile
      source_attribute_on_join_resource :collection_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :import_files
    end
  end

  actions do
    defaults [:create, :update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
    end
  end

  code_interface do
    define_for DataAggregator.Platform
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "collections"
    repo DataAggregator.Repo
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  graphql do
    type :collection

    queries do
      get :get_collection, :read
      list :list_collections, :read
    end

    mutations do
      create :create_collection, :create
      update :update_collection, :update
      destroy :destroy_collection, :destroy
    end
  end

  json_api do
    type "collection"

    routes do
      base("/collections")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
