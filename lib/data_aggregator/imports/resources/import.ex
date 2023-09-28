defmodule DataAggregator.Imports.Import do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "import"
    attribute :url, :string, allow_nil?: false
    attribute :metaData, :map
    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    create :upload_file do
      manual DataAggregator.UploadFile
    end
  end

  json_api do
    type "import"

    routes do
      base("/imports")

      get(:read)
      index(:read)
      post(:create)
      post(:upload_file, route: "/upload")
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :import

    queries do
      get :get_import, :read
      list :list_imports, :read
    end

    mutations do
      create :create_import, :create
      update :update_import, :update
      destroy :destroy_import, :destroy
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
    belongs_to :dataset, DataAggregator.Imports.Dataset
  end
end

defmodule DataAggregator.UploadFile do
  use Ash.Resource.ManualCreate

  alias DataAggregator.Imports.Import

  def create(file, _, _) do
    # this is test code, test it!
    provider = %{id: "1", name: "museum1"}
    collection = %{id: "1", name: "first-collection", metaData: "{}"}
    dataset = %{
      id: "2",
      unique_id: "test-dataset",
      name: "my-dataset",
      metaData: "{}",
      version: 1
    }

    path = file.attributes.url
    meta_data = file.attributes.metaData

    {:ok, file_name} =
      DataAggregator.FileUpload.store(
        {path, %{provider: provider, collection: collection, dataset: dataset}}
      )

    import = %Import{url: "#{path}/#{file_name}", metaData: meta_data}

    # for reasons this doesn't work at all...
    # Import
    #   |> Ash.Changeset.for_create(:create)
    #   |> DataAggregator.Imports.create!(import)

    {:ok, import}
  end
end
