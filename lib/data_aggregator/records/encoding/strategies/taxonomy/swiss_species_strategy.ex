defmodule DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy do
  @moduledoc """
    Encode Records with the gbif swiss species registry catalog
  """

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  require Logger

  # the input attributes are the attributes that will be used to query the catalog, so far we only use the tax_taxon_id
  @input_attribute hd(Catalog.get_input_dwc_attributes(:swiss_species))

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes Catalog.get_output_attributes(:swiss_species)

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
    case SwissSpecies.get_by_usage_key(Map.get(record, @input_attribute)) do
      {:ok, result} ->
        {:ok,
         result
         |> Map.from_struct()
         |> Strategy.update_encoded_record(record, @output_attributes)}

      {:error, %Ash.Error.Query.NotFound{}} ->
        Logger.warning("no matching record found for taxon_id: #{record.tax_taxon_id}")

        {:ok, record}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(record_id, error) do
    Logger.error("Error while encoding the record #{record_id} with the swiss species catalog: #{inspect(error)}")
  end
end
