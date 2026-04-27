defmodule DataAggregator.Repo.SlowQueryLogger do
  @moduledoc """
  Telemetry handler that reports slow database queries to Sentry as warnings.

  Listens for `[:data_aggregator, :repo, :query]` events emitted by Ecto and
  reports any query whose `total_time` (queue + execute + decode) exceeds the
  configured threshold via `Sentry.capture_message/2` (level `:warning`) and
  a `Logger.warning/2` for stdout/log aggregator visibility.

  Configured via `:slow_query_threshold_ms` under the `:data_aggregator` app
  env. When unset, `attach/0` is a no-op so the handler is inactive in
  dev/test by default.

  Only the parameterized SQL is forwarded to Sentry; query parameters are
  intentionally omitted to avoid leaking PII. Call-site stacktraces are
  included when the Repo is configured with `stacktrace: true`.

  Transaction-management queries (BEGIN/COMMIT/ROLLBACK/SAVEPOINT/RELEASE)
  are ignored because their reported time mostly reflects connection idle
  time rather than actual database work.
  """

  require Logger

  @event [:data_aggregator, :repo, :query]
  @handler_id {__MODULE__, :slow_query}
  @max_query_length 2_000
  @ignored_query_prefixes ~w(BEGIN COMMIT ROLLBACK SAVEPOINT RELEASE)

  @doc """
  Attach the handler if `:slow_query_threshold_ms` is configured.
  """
  @spec attach() :: :ok | :skipped | {:error, term()}
  def attach do
    case Application.get_env(:data_aggregator, :slow_query_threshold_ms) do
      ms when is_integer(ms) and ms > 0 ->
        :telemetry.attach(@handler_id, @event, &__MODULE__.handle_event/4, %{threshold_ms: ms})

      _ ->
        :skipped
    end
  end

  @doc false
  def handle_event(_event, measurements, metadata, %{threshold_ms: threshold_ms}) do
    with native when is_integer(native) <- measurements[:total_time],
         total_ms = System.convert_time_unit(native, :native, :millisecond),
         true <- total_ms >= threshold_ms,
         false <- ignored?(metadata[:query]) do
      report(total_ms, measurements, metadata)
    end

    :ok
  rescue
    e ->
      Logger.error(
        "SlowQueryLogger handler error: #{Exception.message(e)}\n" <>
          Exception.format_stacktrace(__STACKTRACE__)
      )

      :ok
  end

  defp ignored?(nil), do: true

  defp ignored?(query) when is_binary(query) do
    Enum.any?(@ignored_query_prefixes, &String.starts_with?(query, &1))
  end

  defp report(total_ms, measurements, metadata) do
    source_label = to_string(metadata[:source] || "unknown")
    extra = build_extra(total_ms, measurements, metadata)

    Logger.warning("Slow query (#{total_ms} ms) on #{source_label}")

    _ =
      Sentry.capture_message("Slow database query on %s",
        interpolation_parameters: [source_label],
        level: :warning,
        tags: %{slow_query: true, source: source_label},
        extra: extra,
        stacktrace: stacktrace(metadata[:stacktrace])
      )

    :ok
  end

  defp build_extra(total_ms, measurements, metadata) do
    %{
      total_time_ms: total_ms,
      query_time_ms: native_to_ms(measurements[:query_time]),
      queue_time_ms: native_to_ms(measurements[:queue_time]),
      decode_time_ms: native_to_ms(measurements[:decode_time]),
      idle_time_ms: native_to_ms(measurements[:idle_time]),
      source: metadata[:source],
      query: truncate(metadata[:query])
    }
  end

  defp native_to_ms(nil), do: nil
  defp native_to_ms(native), do: System.convert_time_unit(native, :native, :millisecond)

  defp truncate(nil), do: nil

  defp truncate(query) when is_binary(query) do
    if byte_size(query) > @max_query_length do
      binary_part(query, 0, @max_query_length) <> "…"
    else
      query
    end
  end

  defp stacktrace(stacktrace) when is_list(stacktrace) and stacktrace != [], do: stacktrace
  defp stacktrace(_), do: []
end
