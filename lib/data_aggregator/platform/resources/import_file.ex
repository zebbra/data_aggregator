defmodule DataAggregator.Platform.ImportFile do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Platform.Collection

  attributes do
    uuid_attribute :id, prefix: "if"
    attribute :amount_of_rows, :integer
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :upload_file do
      argument :path, :string, allow_nil?: false
      argument :collection_id, :string, allow_nil?: false
      change manage_relationship(:collection_id, :collection, type: :append)
      change manage_relationship(:path, :attachment, value_is_key: :path, type: :create)
    end
  end

  code_interface do
    define_for DataAggregator.Platform
    define :upload_file
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "import_files"
    repo DataAggregator.Repo
  end

  graphql do
    type :import_file

    queries do
      get :get_import_file, :read
      list :list_import_files, :read
    end

    mutations do
      create :create_import_file, :create
      update :update_import_file, :update
      destroy :destroy_import_file, :destroy
    end
  end

  json_api do
    type "import_file"

    routes do
      base("/import_files")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
