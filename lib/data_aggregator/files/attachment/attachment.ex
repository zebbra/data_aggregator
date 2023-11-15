defmodule DataAggregator.Files.Attachment do
  @moduledoc """
  Resource representing a file stored in the file storage (local or S3).

  See `DataAggregator.Files` for usage examples.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias __MODULE__

  attributes do
    uuid_attribute :id, prefix: "fat"
    attribute :filename, :string, allow_nil?: false
    attribute :byte_size, :integer, allow_nil?: false
    timestamps()
  end

  calculations do
    calculate :url, :string, Attachment.Calculations.Url do
      argument :signed, :boolean, default: true
      argument :expires_in, :integer, default: 100
    end

    calculate :cached_file, :string, Attachment.Calculations.CachedFile
  end

  actions do
    read :read do
      primary? true
      prepare build(load: [:url])
    end

    create :import_from_path do
      primary? true
      accept [:filename]
      argument :path, :string, allow_nil?: false
      change Attachment.Changes.StoreFile
    end

    destroy :destroy do
      primary? true
      change Attachment.Changes.DeleteFile
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
