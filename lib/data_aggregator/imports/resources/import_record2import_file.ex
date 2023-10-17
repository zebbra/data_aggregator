defmodule DataAggregator.Imports.ImportRecord2ImportFile do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.ImportRecord
  alias DataAggregator.Imports.ImportFile

  postgres do
    table "import_records2import_files"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "ir2if"

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "import_record2import_file"

    primary_key do
      keys([:import_record_id, :import_file_id])
      delimiter("_")
    end

    routes do
      base("/import_records2import_files")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :import_record2import_file

    queries do
      get :get_import_record2import_file, :read
      list :list_import_records2import_files, :read
    end

    mutations do
      create :create_import_record2import_file, :create
      update :update_import_record2import_file, :update
      destroy :destroy_import_record2import_file, :destroy
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
    belongs_to :import_record, ImportRecord, primary_key?: true, allow_nil?: false

    belongs_to :import_file, ImportFile do
      api DataAggregator.Imports
      primary_key? true
      allow_nil? false
    end
  end
end
