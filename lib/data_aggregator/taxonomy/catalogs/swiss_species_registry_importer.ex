defmodule DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistryImporter do
  @moduledoc """
  Import Swiss Species Registry catalog from NDJSON file.

  Each line in the NDJSON file has the structure:
  ```json
  {
    "key": "Scientific Name",
    "value": {
      "result": [{
        "id": "center:id",
        "usage": {
          "status": "accepted" | "synonym",
          "label": "...",
          "name": { "rank": "..." },
          "accepted": { "name": { "label": "..." } }  // only for synonyms
        }
      }]
    }
  }
  ```

  ## Center Mapping

  The center is extracted from the `id` field (e.g., "infofauna:10000" -> "infofauna").
  The "nism" center is mapped to `:swissbryophytes`.
  """

  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry

  require Logger

  @center_mapping %{
    "infofauna" => :infofauna,
    "infoflora" => :infoflora,
    "nism" => :swissbryophytes,
    "swissfungi" => :swissfungi,
    "swisslichens" => :swisslichens,
    "vogelwarte" => :vogelwarte
  }

  @batch_size 1000
  @initial_counts %{created: 0, no_results: 0, duplicate_entries: 0, bulk_create_errors: 0}

  @doc """
  Import Swiss Species Registry from a JSON file.
  """
  @spec import_from_json(String.t()) :: map()
  def import_from_json(path) do
    Logger.info("[swiss_species_registry_importer] Starting import from #{path}")

    {time_ms, counts} = :timer.tc(fn -> do_import(path) end, :millisecond)

    log_summary(counts, time_ms)
    counts
  end

  defp do_import(path) do
    path
    |> File.stream!(:line)
    |> Stream.map(&Jason.decode!/1)
    |> Stream.map(&parse_entry/1)
    |> Stream.chunk_every(@batch_size)
    |> Enum.reduce(@initial_counts, &process_batch/2)
  end

  # Entry parsing - converts JSON to {:ok, attrs} or {:error, reason}

  defp parse_entry(%{"value" => %{"result" => []}}), do: {:error, :no_results}

  defp parse_entry(%{"value" => %{"result" => result}}) when length(result) > 1, do: {:error, :duplicate_entries}

  defp parse_entry(%{"value" => %{"result" => [result]}}), do: {:ok, build_attrs(result)}

  defp build_attrs(%{"id" => id, "usage" => usage}) do
    {center, taxon_id_ch} = parse_id(id)
    status = usage["status"]

    %{
      scientific_name: usage["label"],
      taxon_id_ch: taxon_id_ch,
      accepted_name_usage: get_accepted_name_usage(usage, status),
      center: center,
      rank: get_in(usage, ["name", "rank"]),
      status: status
    }
  end

  # Batch processing

  defp process_batch(batch, counts) do
    {valid_entries, error_counts} = partition_batch(batch)
    counts = merge_counts(counts, error_counts)

    case valid_entries do
      [] -> counts
      entries -> bulk_create(entries, counts)
    end
  end

  defp partition_batch(batch) do
    Enum.reduce(batch, {[], @initial_counts}, fn
      {:ok, attrs}, {valid, errors} -> {[attrs | valid], errors}
      {:error, reason}, {valid, errors} -> {valid, increment(errors, reason)}
    end)
  end

  defp bulk_create(entries, counts) do
    entries
    |> Ash.bulk_create(SwissSpeciesRegistry, :create,
      return_errors?: true,
      stop_on_error?: false,
      return_records?: true
    )
    |> update_counts_from_result(counts, length(entries))
  end

  defp update_counts_from_result(%Ash.BulkResult{status: :success}, counts, batch_size) do
    increment(counts, :created, batch_size)
  end

  defp update_counts_from_result(%Ash.BulkResult{status: :error, errors: errors}, counts, _) do
    increment(counts, :bulk_create_errors, safe_length(errors))
  end

  defp update_counts_from_result(%Ash.BulkResult{records: records, errors: errors}, counts, _) do
    counts
    |> increment(:created, safe_length(records))
    |> increment(:bulk_create_errors, safe_length(errors))
  end

  # Count helpers

  defp increment(counts, key, amount \\ 1), do: Map.update!(counts, key, &(&1 + amount))
  defp merge_counts(c1, c2), do: Map.merge(c1, c2, fn _k, v1, v2 -> v1 + v2 end)
  defp safe_length(list) when is_list(list), do: length(list)
  defp safe_length(_), do: 0

  defp log_summary(counts, time_ms) do
    Logger.info("""
    [swiss_species_registry_importer] Import completed in #{time_ms} ms
      Created: #{counts.created}
      Skipped (no results): #{counts.no_results}
      Skipped (duplicate entries): #{counts.duplicate_entries}
      Failed (bulk create errors): #{counts.bulk_create_errors}
    """)
  end

  # Public helpers with doctests

  @doc """
  Parse the ID field to extract center and taxon ID.

  ## Examples

      iex> parse_id("infofauna:10000")
      {:infofauna, "10000"}

      iex> parse_id("infoflora:12345")
      {:infoflora, "12345"}

      iex> parse_id("nism:67890")
      {:swissbryophytes, "67890"}

      iex> parse_id("swissfungi:11111")
      {:swissfungi, "11111"}

      iex> parse_id("swisslichens:22222")
      {:swisslichens, "22222"}

      iex> parse_id("vogelwarte:33333")
      {:vogelwarte, "33333"}

      iex> parse_id("INFOFAUNA:10000")
      {:infofauna, "10000"}

  """
  @spec parse_id(String.t()) :: {atom(), String.t()}
  def parse_id(id) do
    [center_str, taxon_id] = String.split(id, ":")
    center = Map.fetch!(@center_mapping, String.downcase(center_str))
    {center, taxon_id}
  end

  @doc """
  Get the accepted name usage based on the status.

  For accepted taxa, returns usage.label.
  For synonyms, returns usage.accepted.name.label.
  For unknown statuses, returns nil.

  ## Examples

      iex> get_accepted_name_usage(%{"label" => "Species name"}, "accepted")
      "Species name"

      iex> get_accepted_name_usage(%{"label" => "Synonym name", "accepted" => %{"name" => %{"label" => "Accepted species name"}}}, "synonym")
      "Accepted species name"

      iex> get_accepted_name_usage(%{"label" => "Some name"}, "unknown")
      nil

  """
  @spec get_accepted_name_usage(map(), String.t()) :: String.t() | nil
  def get_accepted_name_usage(usage, "accepted"), do: usage["label"]
  def get_accepted_name_usage(usage, "synonym"), do: get_in(usage, ["accepted", "name", "label"])
  def get_accepted_name_usage(_usage, _status), do: nil
end
