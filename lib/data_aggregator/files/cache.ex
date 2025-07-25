defmodule DataAggregator.Files.Cache do
  @moduledoc """
  This module provides functions for locally caching `DataAggregator.Files.Attachment` files.

  The files are stored in the directory specified by `DataAggregator.Files.cache_dir/0`.
  """

  alias DataAggregator.Files
  alias DataAggregator.Files.Attachment

  require Logger

  @doc """
  Stores remote file in the local cache and returns the path to the cached file.

  If the file is already cached, the cached file path is returned.
  """
  def store(%Attachment{} = attachment) do
    with {:ok, attachment} <- Ash.load(attachment, [:url], lazy?: true) do
      maybe_download(attachment)
    end
  end

  @doc """
  Deletes the cached file for the given `DataAggregator.Files.Attachment`.
  """
  def delete(%Attachment{} = attachment) do
    path = cached_file_path(attachment)

    if File.exists?(path) do
      Logger.info("Deleting cached file: #{path}")
      File.rm(path)
    else
      :ok
    end
  end

  @doc """
  Returns `true` if the given `DataAggregator.Files.Attachment` is cached.
  """
  def cached?(%Attachment{} = attachment) do
    attachment |> cached_file_path() |> File.exists?()
  end

  defp maybe_download(%Attachment{url: url} = attachment) do
    path = cached_file_path(attachment)

    if File.exists?(path) do
      {:ok, path}
    else
      download_to(url, path)
    end
  end

  defp cached_file_path(%Attachment{id: id, filename: filename}) do
    [Files.cache_dir(), id, filename]
    |> Path.join()
    |> Path.expand()
  end

  defp download_to(url, path) do
    Logger.debug("Downloading #{url} to #{path}")

    with :ok <- create_cache_dir(path) do
      case Req.get(url: url, into: File.stream!(path)) do
        {:ok, %Req.Response{status: 200}} ->
          {:ok, path}

        {:ok, %Req.Response{status: status}} ->
          {:error, "Failed to download #{url} (status: #{status})"}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp create_cache_dir(path) do
    dir = Path.dirname(path)

    if File.exists?(dir) do
      :ok
    else
      Logger.info("Creating cache directory: #{dir}")
      File.mkdir_p(dir)
    end
  end
end
