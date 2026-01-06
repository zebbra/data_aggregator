defmodule DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy do
  @moduledoc """
  Encode Records with the Swiss Species Registry catalog.

  Uses `tax_scientific_name` to lookup in the SwissSpeciesRegistry table.
  The lookup is based on scientific name rather than GBIF taxon ID.

  ## Encoding Results

  - **Match found**: Populates taxon_id_ch, accepted_name_usage, center, rank,
    registered_at, and registered fields
  - **No match**: Sets registered to false
  - **Duplicate in registry**: Returns error "Found duplicate in Swiss Species Registry."
  - **Out of scope (non-CH country)**: Sets center to "Out of Scope", registered to true
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog
  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry

  require Logger

  # Input: use tax_scientific_name for lookup
  @input_attribute hd(Catalog.get_input_dwc_attributes(:swiss_species))

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes Catalog.get_output_attributes(:swiss_species)

  @doc """
  Lookup the Swiss Species Registry and return the encoded record.
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
    with {:ok, scientific_name} <- get_scientific_name(encoded_record),
         {:ok, result} <- SwissSpeciesRegistry.get_by_scientific_name(scientific_name),
         {:ok, _} <- verify_result(result),
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

  defp verify_result(result) when is_list(result) and length(result) > 1 do
    {:error, "Found duplicate in Swiss Species Registry."}
  end

  defp verify_result(result) do
    case result do
      %{
        taxon_id_ch: taxon_id_ch,
        accepted_name_usage: accepted_name_usage,
        rank: rank,
        center: center
      }
      when not is_nil(taxon_id_ch) and
             not is_nil(accepted_name_usage) and
             not is_nil(rank) and
             not is_nil(center) ->
        {:ok, result}

      _ ->
        {:error, "Swiss Species Registry entry is missing required information."}
    end
  end

  @spec get_scientific_name(EncodedRecord.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp get_scientific_name(encoded_record) do
    case Map.get(encoded_record, @input_attribute) do
      nil -> {:error, "scientific_name is empty"}
      "" -> {:error, "scientific_name is empty"}
      scientific_name -> {:ok, scientific_name}
    end
  end

  defp country_check(%{loc_country_code: country_code}, _result) when country_code in ["CH", "ch", "CHE", "che"] do
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
    Logger.warning("[swiss_species] no matching entry found for scientific_name: #{encoded_record.tax_scientific_name}")

    encoded_record =
      Strategy.update_encoded_record(
        %{registered: false},
        encoded_record,
        @output_attributes,
        ctx
      )

    {:ok, encoded_record}
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
  Convert values to string if necessary.

  ## Examples

      iex> convert_to_string({:foo, nil})
      nil

      iex> convert_to_string({:center, :infofauna})
      "infofauna"

      iex> convert_to_string({:foo, "bar"})
      "bar"
  """
  @spec convert_to_string({atom(), any()}) :: String.t() | nil
  def convert_to_string(key_value)

  def convert_to_string({_, nil}), do: nil
  def convert_to_string({_, value}) when is_binary(value), do: value
  def convert_to_string({:center, value}) when is_atom(value), do: Atom.to_string(value)
  def convert_to_string({_, value}), do: value
end
