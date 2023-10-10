defmodule DataAggregator.Imports.ImportFile do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshJsonApi.Resource]

  postgres do
    table "import_files"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "import_file"

    attribute :url, :string do
      allow_nil? false
    end

    attribute :parsed_data, :map

    attribute :meta_data, :map

    attribute :import_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :upload_file do
      manual DataAggregator.UploadFile
    end
  end

  json_api do
    type "import_file"

    routes do
      base("/import_files")

      get(:read)
      index(:read)
      post(:create)
      post(:upload_file, route: "/upload")
      patch(:update)
      delete(:destroy)
    end
  end

  # graphql do
  #   type :import_file

  #   queries do
  #     get :get_import_file, :read
  #     list :list_import_files, :read
  #   end

  #   mutations do
  #     create :create_import_file, :create
  #     update :update_import_file, :update
  #     destroy :destroy_import_file, :destroy
  #   end
  # end

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
  end
end
