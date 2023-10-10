defmodule DataAggregator.Imports.Import do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Imports.StaticAsset
  alias DataAggregator.Imports.ImportFile
  alias DataAggregator.TaxonomyData.Record

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "import"

    attribute :name, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    attribute :version, :integer do
      allow_nil? false
      filterable? true
    end

    attribute :import_data, :map

    attribute :collection_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  # graphql do
  #   type :import

  #   queries do
  #     get :get_import, :read
  #     list :list_imports, :read
  #   end

  #   mutations do
  #     create :create_import, :create
  #     update :update_import, :update
  #     destroy :destroy_import, :destroy
  #   end
  # end

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    has_many :records, Record
    has_many :static_assets, StaticAsset
    has_many :import_files, ImportFile
  end
end

defmodule DataAggregator.UploadFile do
  use Ash.Resource.ManualCreate

  alias DataAggregator.Imports.ImportFile

  def create(file, _, _) do
    # this is test code, test it!
    institution = %{id: "1", name: "museum1"}
    collection = %{id: "1", name: "first-collection", meta_data: "{}"}

    import = %{
      id: "2",
      unique_id: "test-dataset",
      name: "my-dataset",
      meta_data: "{}",
      version: 1,
      collection_id: "496752bc-6743-11ee-8c99-0242ac120002"
    }

    path = file.attributes.url
    meta_data = file.attributes.meta_data

    {:ok, file_name} =
      DataAggregator.FileUpload.store(
        {path, %{institution: institution, collection: collection, import: import}}
      )

    import_file = %ImportFile{url: "#{path}/#{file_name}", meta_data: meta_data}

    # for reasons this doesn't work at all...
    # ImportFile
    #   |> Ash.Changeset.for_create(:create)
    #   |> DataAggregator.Imports.ImportFile.create!(import_file)

    {:ok, import_file}
  end
end
