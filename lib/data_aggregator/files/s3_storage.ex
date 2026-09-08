defmodule DataAggregator.Files.S3Storage do
  @moduledoc """
  Waffle storage backend that behaves exactly like `Waffle.Storage.S3` except that it
  never sends a canned ACL (`x-amz-acl`) with uploads.

  See https://github.com/zebbra/data_aggregator/issues/1099
  """

  @behaviour Waffle.Storage

  alias ExAws.S3
  alias ExAws.S3.Upload

  require Logger

  @impl true
  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})
    s3_bucket = s3_bucket(definition, {file, scope})
    s3_key = Path.join(destination_dir, file.file_name)

    # Deliberately no `:acl` key here - see the moduledoc.
    s3_options =
      version
      |> definition.s3_object_headers({file, scope})
      |> ensure_keyword_list()

    do_put(file, {s3_bucket, s3_key, s3_options})
  end

  @impl true
  def url(definition, version, file_and_scope, options \\ []) do
    Waffle.Storage.S3.url(definition, version, file_and_scope, options)
  end

  @impl true
  def delete(definition, version, file_and_scope) do
    Waffle.Storage.S3.delete(definition, version, file_and_scope)
  end

  defp ensure_keyword_list(list) when is_list(list), do: list
  defp ensure_keyword_list(map) when is_map(map), do: Map.to_list(map)

  defp s3_bucket(definition, file_and_scope) do
    file_and_scope |> definition.bucket() |> parse_bucket()
  end

  defp parse_bucket({:system, env_var}) when is_binary(env_var), do: System.get_env(env_var)
  defp parse_bucket(name), do: name

  # If the file is stored as a binary in-memory, send to S3 in a single request
  defp do_put(%Waffle.File{binary: file_binary} = file, {s3_bucket, s3_key, s3_options}) when is_binary(file_binary) do
    s3_bucket
    |> S3.put_object(s3_key, file_binary, s3_options)
    |> ExAws.request()
    |> case do
      {:ok, _res} -> {:ok, file.file_name}
      {:error, error} -> {:error, error}
    end
  end

  # If the file is a stream, send it to S3 as a multi-part upload
  defp do_put(%Waffle.File{stream: file_stream} = file, {s3_bucket, s3_key, s3_options}) when is_struct(file_stream) do
    file_stream
    |> chunk_stream()
    |> do_put_stream(file, {s3_bucket, s3_key, s3_options})
  end

  # Stream the file from disk and upload to S3 as a multi-part upload
  defp do_put(file, {s3_bucket, s3_key, s3_options}) do
    file.path
    |> Upload.stream_file()
    |> do_put_stream(file, {s3_bucket, s3_key, s3_options})
  end

  defp do_put_stream(stream, file, {s3_bucket, s3_key, s3_options}) do
    stream
    |> S3.upload(s3_bucket, s3_key, s3_options)
    |> ExAws.request()
    |> case do
      {:ok, %{status_code: 200}} -> {:ok, file.file_name}
      {:ok, :done} -> {:ok, file.file_name}
      {:error, error} -> {:error, error}
    end
  rescue
    e in ExAws.Error ->
      Logger.error(inspect(e))
      Logger.error(e.message)
      {:error, :invalid_bucket}
  end

  defp chunk_stream(stream, chunk_size \\ 5 * 1024 * 1024) do
    Stream.chunk_while(
      stream,
      "",
      fn element, acc ->
        if String.length(acc) >= chunk_size do
          {:cont, acc, element}
        else
          {:cont, acc <> element}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, acc, []}
      end
    )
  end
end
