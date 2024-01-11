defmodule DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy do
  @moduledoc """
    Encode Records with the gbif swiss species registry catalog
  """

  require Logger

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes [
    {:tax_taxon_id_ch, :taxon_id_ch},
    {:tax_accepted_name_usage, :accepted_name},
    {:tax_accepted_name_usage_id, :accepted_usage_key},
    {:tax_scientific_name, :scientific_name},
    {:tax_taxon_rank, :rank}
  ]

  @doc """
    lookup the swiss species registry and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t()) :: EncodingResult.t()
  def apply_strategy(record) do
    case process_record(record) do
      {:ok, record} ->
        {:ok, record}

      {:error, error} ->
        handle_error(record.id, error)

        {:error, error}
    end
  rescue
    error ->
      handle_error(record.id, error)

      {:error, error}
  end

  @spec process_record(EncodedRecord.t()) :: EncodingResult.t()
  defp process_record(record) do
    case SwissSpecies.get_by_usage_key(record.tax_taxon_id) do
      {:ok, result} ->
        {:ok,
         result
         |> Map.from_struct()
         |> Strategy.update_encoded_record(record, @output_attributes)}

      {:error, %Ash.Error.Query.NotFound{}} ->
        {:error, "no matching record found for taxon_id: #{record.tax_taxon_id}"}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(record_id, error) do
    Logger.error(
      "Error while encoding the record #{record_id} with the swiss species catalog: #{inspect(error)}"
    )
  end
end
