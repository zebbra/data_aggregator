defmodule DataAggregator.Platform.ImportFile do
  @moduledoc """
  Resource for importing records into a collection from a file.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Platform.Collection

  attributes do
    uuid_attribute :id, prefix: "if"

    attribute :amount_of_rows, :integer
    attribute :columns, {:array, :string}

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end
  end

  actions do
    defaults [:read]

    create :create_from_path do
      primary? true
      argument :path, :string, allow_nil?: false
      argument :collection, Collection, allow_nil?: false

      change manage_relationship(:collection, :collection, type: :append)
      change manage_relationship(:path, :attachment, value_is_key: :path, type: :create)

      change DataAggregator.Platform.Changes.DetectColumns
    end
  end

  code_interface do
    define_for DataAggregator.Platform
    define :create_from_path, args: [:collection, :path]
    define :read
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
      create :create_import_file, :create_from_path
    end
  end

  json_api do
    type "import_file"

    routes do
      base("/import_files")

      get(:read)
      index :read
      post(:create_from_path)
    end
  end
end
