defmodule DataAggregator.Imports.ImportFile do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.Collection

  postgres do
    table "import_files"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "if"

    attribute :url, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

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

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    belongs_to :collection, Collection
  end
end

defmodule DataAggregator.UploadFile do
  use Ash.Resource.ManualCreate

  alias DataAggregator.Imports.Institution
  alias DataAggregator.Imports.ImportFile
  # alias DataAggregator.Imports.ImportRecord

  def create(file, _, _) do
    # this is test code, test it!
    institution = %Institution{
      id: "1",
      name: "museum1"
    }

    # get the import_record according to its id and then add it to the import_file
    # import_record = %ImportRecord{
    #   id: "2",
    #   unique_qualifier: "my-dataset",
    #   meta_data: "{}",
    #   import_data: "{}"
    # }

    path = file.attributes.url
    meta_data = file.attributes.meta_data

    {:ok, file_name} =
      DataAggregator.FileUpload.store({path, %{institution: institution}})

    import_file = %ImportFile{url: "#{path}/#{file_name}", meta_data: meta_data}

    # for reasons this doesn't work at all...
    # ImportFile
    #   |> Ash.Changeset.for_create(:create)
    #   |> DataAggregator.Imports.ImportFile.create!(import_file)

    {:ok, import_file}
  end
end
