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
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    with {:ok, taxon_id} <- get_taxon_id(encoded_record),
         {:ok, result} <- SwissSpecies.get_by_usage_key(taxon_id),
         {:ok, :valid} <- country_check(encoded_record, result) do
      encoded_record =
        result
        |> Map.from_struct()
        |> maybe_convert_values()
        |> Map.put(:registered_at, DateTime.utc_now())
        |> Map.put(:registered, true)
        |> Strategy.update_encoded_record(encoded_record, @output_attributes, ctx)

      {:ok, encoded_record}
    else
      {:error, %Ash.Error.Query.NotFound{}} ->
        handle_not_found_or_invalid(encoded_record, ctx)

      {:error, %Ash.Error.Invalid{}} ->
        handle_not_found_or_invalid(encoded_record, ctx)

      {:out_of_scope, result} ->
        handle_out_of_scope(encoded_record, result, ctx)

      {:error, error} ->
        {:error, error, encoded_record}
    end
  end

  defp country_check(%{loc_country_code: country_code} = _encoded_record, _result) when country_code in ["CH", "ch"] do
    {:ok, :valid}
  end

  defp country_check(_, result) do
    {:out_of_scope, result}
  end

  defp handle_out_of_scope(encoded_record, result, ctx) do
    Logger.info(
      "[swiss_species] encoded_record #{encoded_record.id} is out of scope due to country_code: #{encoded_record.loc_country_code}"
    )

    encoded_record =
      result
      |> Map.from_struct()
      |> maybe_convert_values()
      |> Map.put(:registered_at, DateTime.utc_now())
      |> Map.put(:registered, true)
      |> Map.put(:center, "Out of Scope")
      |> Strategy.update_encoded_record(encoded_record, @output_attributes, ctx)

    {:ok, encoded_record}
  end

  defp handle_not_found_or_invalid(encoded_record, ctx) do
    Logger.warning("[swiss_species] no matching encoded_record found for taxon_id: #{encoded_record.tax_taxon_id}")

    encoded_record =
      Strategy.update_encoded_record(
        %{registered: false},
        encoded_record,
        @output_attributes,
        ctx
      )

    {:ok, encoded_record}
  end

  @spec get_taxon_id(map()) :: {:ok, integer()} | {:error, String.t()}
  defp get_taxon_id(encoded_record) do
    case Map.get(encoded_record, @input_attribute) do
      nil -> {:error, "taxon_id is empty"}
      taxon_id -> {:ok, taxon_id}
    end
  end

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[swiss_species] Error while encoding the encoded_record #{encoded_record_id} with the swiss species catalog: #{inspect(error)}"
    )
  end

  @spec maybe_convert_values(map()) :: map()
  defp maybe_convert_values(record) do
    Enum.reduce(record, %{}, fn {key, value}, acc ->
      Map.put(acc, key, convert_to_string({key, value}))
    end)
  end

  @doc """
    Convert values to string if necessary. Implement function convert_to_string/1 for each attribute of the encoded datastructure

    %{
      id: "spc_02vSBcLj4G1ReRVJNXDLVo",
      calculations: %{},
      aggregates: %{},
      __lateral_join_source__: nil,
      __meta__: #Ecto.Schema.Metadata<:built, "swiss_species">,
      __metadata__: %{},
      __order__: nil,
      center: nil,
      rank: "SPECIES",
      inserted_at: nil,
      updated_at: nil,
      scientific_name: "Enantiulus dentigerus (Verhoeff, 1901)",
      taxon_id_ch: 15311,
      accepted_name: "Enantiulus dentigerus (Verhoeff, 1901)",
      accepted_usage_key: "1669856",
      usage_key: 2435194
    }

    ## Example

    iex> convert_to_string({:foo, nil})
    nil

    iex> convert_to_string({:accepted_usage_key, "12345"})
    "12345"

    iex> convert_to_string({:accepted_usage_key, 12345})
    "12345"

    iex> convert_to_string({:foo, "bar"})
    "bar"
  """
  @spec convert_to_string({atom(), any()}) :: String.t() | nil
  def convert_to_string(key_value)

  def convert_to_string({_, nil}), do: nil
  def convert_to_string({_, value}) when is_binary(value), do: value
  def convert_to_string({:accepted_usage_key, value}), do: Integer.to_string(value)
  def convert_to_string({_, value}), do: value
end
