defmodule DataAggregator.Files do
  @moduledoc """
  This context provides a `DataAggregator.Files.Attachment` resource for managing files.

  ## Usage

  Use `DataAggregator.Files.Attachment.import_from_path/1` to import a file from the local filesystem:

  ```elixir
  alias DataAggregator.Files.Attachment

  {:ok, attachment} = Attachment.import_from_path("/path/to/file.csv")
  ```

  The `DataAggregator.Files.Attachment` struct contains the following calculations:

  * `url` - The remote storage URL of the file (by default this returns a signed URL)
  * `cached_file` - The path to the cached file on the local filesystem. This calculation will download the file if it is not already cached.

  ```elixir
  {:ok, attachment} = Attachment.get_by_id("fat_123", load: [:url, :cached_file])

  attachment.url # => "https://s3.amazonaws.com/my-bucket/..."
  attachment.cached_file # => "/path/to/cache/fat_123/file.csv"
  ```

  Deleting the file will also remove the file from the remote storage:

  ```elixir
  {:ok, _} = Attachment.destroy(attachment)
  ```

  ## Configuration

  By default, cached files are stored in a subdirectory of `System.tmp_dir!()` directory, but the directory can
  be configured in the `data_aggregator` config:

  ```elixir
  config :data_aggregator, DataAggregator.Files,
    cache_dir: "/path/to/cache"
  ```

  ## Resources

  #{"files-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}

  """

  use Ash.Api

  resources do
    registry DataAggregator.Files.Registry
  end

  @doc """
  Configurations options for the `DataAggregator.Files` context.
  """
  def config, do: Application.get_env(:data_aggregator, __MODULE__, [])

  @doc """
  Returns the directory where cached files are stored.
  """
  def cache_dir do
    default = Path.join([System.tmp_dir!(), "data_aggregator", "files", "cache"])
    Keyword.get(config(), :cache_dir, default)
  end
end
