defmodule DataAggregator.Records.Import do
  @moduledoc """
  Resource for importing records into a collection from a file.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import.Column
  alias DataAggregator.Records.Import.Record, as: ImportRecord

  attributes do
    uuid_attribute :id, prefix: "if"
    attribute :columns, {:array, Column}
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    has_many :import_records, ImportRecord do
    end

    many_to_many :records, DataAggregator.Records.Record do
      api DataAggregator.Records
      through ImportRecord
      join_relationship :import_records
    end
  end

  aggregates do
    count :records_count, :records
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :collection, Collection, allow_nil?: false
      change manage_relationship(:collection, :collection, type: :append)
    end

    create :create_from_path do
      accept []
      argument :path, :string, allow_nil?: false
      argument :collection, Collection, allow_nil?: false
      change manage_relationship(:collection, :collection, type: :append)
      change manage_relationship(:path, :attachment, value_is_key: :path, type: :create)
      change DataAggregator.Records.Changes.DetectColumns
    end

    update :update_mapping do
      accept [:columns]
      change Import.Changes.UpdateMapping
    end

    update :import_records do
      accept []
      change Import.Changes.ImportRecords
      change load([:records_count])
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :create, args: [:collection]
    define :create_from_path, args: [:collection, :path]
    define :update_mapping, args: [:columns]
    define :import_records
    define :destroy
  end

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  graphql do
    type :import

    queries do
      get :get_import, :read
      list :list_imports, :read
    end

    mutations do
      create :create_import, :create_from_path
    end
  end

  json_api do
    type "import"

    routes do
      base("/imports")

      get(:read)
      index :read
      post(:create_from_path)
    end
  end
end
