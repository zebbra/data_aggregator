defmodule DataAggregator.Files.Attachment do
  @moduledoc """
  Resource representing a file stored in the file storage (local or S3).
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  attributes do
    uuid_attribute :id, prefix: "fat"
    attribute :filename, :string, allow_nil?: false
    timestamps()
  end

  calculations do
    calculate :url, :string, DataAggregator.Files.Calculations.Url do
      argument :signed, :boolean, default: true
      argument :expires_in, :integer, default: 100
    end

    calculate :stream, :function, DataAggregator.Files.Calculations.Stream do
      load [:url]
    end
  end

  actions do
    read :read do
      primary? true
      prepare build(load: [:url])
    end

    create :import_from_path do
      primary? true
      argument :path, :string, allow_nil?: false
      change DataAggregator.Files.Changes.StoreFile
    end

    destroy :destroy do
      primary? true
      change DataAggregator.Files.Changes.DeleteFile
    end
  end

  code_interface do
    define_for DataAggregator.Files
    define :read
    define :get_by_id, action: :read, get_by: :id
    define :import_from_path, args: [:path]
    define :destroy
  end

  postgres do
    table "file_attachments"
    repo DataAggregator.Repo
  end
end
