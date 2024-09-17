defmodule DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy do
  @moduledoc """
    Encode Records with the gbif swiss species registry catalog
  """

  alias Ash.Resource.Actions.Implementation.Context
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
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    case process_encoded_record(encoded_record, ctx) do
      {:ok, encoded_record} ->
        {:ok, encoded_record}

      {:error, error, encoded_record} ->
        handle_error(encoded_record.id, error)

        {:error, error, encoded_record}
    end
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error, encoded_record}
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    taxon_id = Map.get(encoded_record, @input_attribute)

    # early return if taxon_id is empty
    if taxon_id === nil, do: raise("taxon_id is empty")

    case SwissSpecies.get_by_usage_key(taxon_id) do
      {:ok, result} ->
        {:ok,
         result
         |> Map.from_struct()
         |> Strategy.update_encoded_record(encoded_record, @output_attributes, ctx)}

      {:error, %Ash.Error.Query.NotFound{}} ->
        Logger.warning("[swiss_species] no matching encoded_record found for taxon_id: #{encoded_record.tax_taxon_id}")

        {:ok, encoded_record}

      {:error, error} ->
        {:error, error, encoded_record}
    end
  end

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[swiss_species] Error while encoding the encoded_record #{encoded_record_id} with the swiss species catalog: #{inspect(error)}"
    )
  end
end
