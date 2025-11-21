defmodule DataAggregator.Files.Attachment do
  @moduledoc """
  Resource representing a file stored in the file storage (local or S3).

  See `DataAggregator.Files` for usage examples.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Files,
    extensions: [AshUUID],
    # to use preparations in primary read's is an anti pattern - prepare build(load: [:url]) - and generates warnings,
    # we do it here intentionally, so we suppress the warning
    primary_read_warning?: false

  alias __MODULE__

  @type t :: %Attachment{}

  @hour 3600
  @day 24 * @hour

  attributes do
    uuid_attribute :id, prefix: "fat", public?: true
    attribute :filename, :string, allow_nil?: false, public?: true
    attribute :byte_size, :integer, allow_nil?: false, public?: true
    attribute :deletable, :boolean, allow_nil?: false, default: false, public?: true

    timestamps public?: true, writable?: false
  end

  calculations do
    calculate :url, :string, Attachment.Calculations.Url do
      argument :signed, :boolean, default: true
      argument :expires_in, :integer, default: @day
    end

    calculate :public_url, :string, expr("#")

    calculate :cached_file, :string, Attachment.Calculations.CachedFile
  end

  actions do
    default_accept :*

    read :read do
      primary? true

      pagination offset?: true, keyset?: true, required?: false
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
      soft? true

      change set_attribute(:deletable, true)
    end

    destroy :hard_destroy do
      require_atomic? false
      change Attachment.Changes.DeleteFile
    end
  end

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: :id
    define :import_from_path, args: [:path]
    define :destroy
    define :hard_destroy
  end

  postgres do
    table "file_attachments"
    repo DataAggregator.Repo
  end
end
