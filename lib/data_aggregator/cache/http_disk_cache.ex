defmodule DataAggregator.Cache.HttpDiskCache do
  @moduledoc """
  Cache Strategy for Req using local disk to save responses.
  Will add a date to the cache file, and will not save if the status is not 200.
  Deletes the cache file if it is expired and then re-requests the resource.

  inspired by https://thibautbarrere.com/2022/09/09/implementing-a-disk-cache-for-elixir-req
  """
  require Logger

  # default cache time is 1 hour
  @max_cache_age_seconds 60 * 60
  # accepted http states for caching according to rfc-editor.org/rfc/rfc7231
  @cachable_response_states [200, 203, 204, 206, 300, 301, 404, 405, 410, 414, 501]

  @default_http_cache_dir Application.compile_env(
                            :data_aggregator,
                            :http_cache_path,
                            :filename.basedir(:user_cache, ~c"http")
                          )

  def attach(%Req.Request{} = request, options \\ []) do
    request
    |> Req.Request.register_options([:cache_dir, :max_cache_age_seconds])
    |> Req.Request.merge_options(options)
    |> Req.Request.append_request_steps(custom_cache: &request_cache_step/1)
    |> Req.Request.prepend_response_steps(custom_cache: &response_cache_step/1)
  end

  defp request_cache_step(request) do
    cache_path = cache_path(request)
    max_cache_age_seconds = request.options[:max_cache_age_seconds] || @max_cache_age_seconds

    if valid_cache_file?(cache_path, max_cache_age_seconds) do
      Logger.debug("File found in cache (#{cache_path})")

      {request, load_cache(cache_path)}
    else
      request
    end
  end

  defp response_cache_step({request, response}) do
    if response.status in @cachable_response_states do
      cache_path = cache_path(request)
      max_cache_age_seconds = request.options[:max_cache_age_seconds] || @max_cache_age_seconds

      if valid_cache_file?(cache_path, max_cache_age_seconds) === false do
        Logger.debug("Saving file to cache (#{cache_path})")

        write_cache(cache_path, response)
      end
    else
      Logger.debug("Status is #{response.status}, not saving file to disk")
    end

    {request, response}
  end

  defp valid_cache_file?(path, max_cache_age_seconds) do
    if File.exists?(path) do
      file_younger_than?(path, max_cache_age_seconds)
    else
      Logger.debug("no cache file at #{path} found")

      false
    end
  end

  # https://github.com/wojtekmach/req/blob/102b9aa6c6ff66f00403054a0093c4f06f6abc2f/lib/req/steps.ex#L1268
  defp cache_path(request) do
    cache_dir =
      request.options[:cache_dir] || @default_http_cache_dir

    cache_key =
      Enum.join(
        [
          request.url.host,
          Atom.to_string(request.method),
          :sha256
          |> :crypto.hash(:erlang.term_to_binary(request.url))
          |> Base.encode16(case: :lower)
        ],
        "-"
      )

    Path.join(cache_dir, cache_key)
  end

  defp write_cache(path, response) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, :erlang.term_to_binary(response))
  end

  defp load_cache(path) do
    path |> File.read!() |> :erlang.binary_to_term()
  end

  defp file_younger_than?(file_path, max_cache_age_seconds) do
    case File.stat(file_path, time: :posix) do
      {:ok, %File.Stat{mtime: mtime}} ->
        current_time = System.system_time(:second)
        oldest_possible_time = current_time - max_cache_age_seconds

        # if file is older than max allowed age, delete it
        if oldest_possible_time > mtime do
          Logger.debug("Cache file is older than #{max_cache_age_seconds} seconds, deleting it")

          File.rm!(file_path)

          false
        else
          true
        end

      {:error, reason} ->
        Logger.error("Error getting file information: #{reason}")

        false
    end
  end
end
