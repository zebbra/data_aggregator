defmodule DataAggregator.Files.Attachment do
  @moduledoc """
  Resource representing a file stored in the file storage (local or S3).

  See `DataAggregator.Files` for usage examples.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Files,
    extensions: [AshUUID, AshOban],
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
    attribute :deleted_at, :utc_datetime, default: nil, public?: true

    timestamps public?: true, writable?: false
  end

  oban do
    triggers do
      trigger :cleanup do
        action :hard_destroy
        read_action :read_deleted
        scheduler_cron "*/5 * * * *"
        queue :attachment_deletion
        worker_module_name Attachment.AshOban.Worker.Cleanup
        scheduler_module_name Attachment.AshOban.Scheduler.Cleanup
      end
    end
  end

  calculations do
    calculate :url, :string, Attachment.Calculations.Url do
      argument :signed, :boolean, default: true
      argument :expires_in, :integer, default: @day
    end

    calculate :public_url, :string, expr("#")

    calculate :cached_file, :string, Attachment.Calculations.CachedFile

    calculate :deleted?, :boolean, expr(not is_nil(deleted_at))
  end

  actions do
    default_accept :*

    read :read do
      primary? true

      pagination offset?: true, keyset?: true, required?: false
      filter expr(not deleted?)

      prepare build(load: [:url, :deleted?])
    end

    read :read_deleted do
      pagination offset?: true, keyset?: true, required?: false

      filter expr(deleted?)

      prepare build(load: [:deleted?])
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

      change set_attribute(:deleted_at, DateTime.utc_now())
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
    define :read_deleted
  end

  postgres do
    table "file_attachments"
    repo DataAggregator.Repo
  end
end
