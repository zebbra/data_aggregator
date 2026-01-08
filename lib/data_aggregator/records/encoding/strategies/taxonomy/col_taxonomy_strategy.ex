defmodule DataAggregator.Records.Encoding.Strategy.CoLTaxonomyStrategy do
  @moduledoc """
    Encode Records with the CoL taxonomy catalog
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.CatalogOfLife, as: CoL
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy

  require Logger

  @doc """
    query the gbif taxanomy api and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    process_encoded_record(encoded_record, ctx)
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    with {:ok, response} <- parse_scientific_name(encoded_record.tax_scientific_name),
         {:ok, parsed_scientific_name} <- validate_parsed_name(response),
         {:ok, species} <- lookup_species_by_name(parsed_scientific_name),
         {:ok, encoded_species} <- validate_species(species) do
      encoded_record =
        Strategy.update_encoded_record(encoded_species, encoded_record, [], ctx)

      {:ok, encoded_record}
    else
      {:error, error} ->
        {:error, error, encoded_record}
    end
  end

  @spec parse_scientific_name(String.t()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  defp parse_scientific_name(unparsed_scientific_name) do
    case CoL.RestAPI.parse_name(unparsed_scientific_name) do
      {:ok, body} ->
        {:ok, body}

      {:error, error} ->
        {:error,
         "[col_taxonomy] Error while parsing scientific name with CoL taxonomy api: #{inspect(error, limit: :infinity)}"}
    end
  end

  @spec validate_parsed_name(Req.Response.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp validate_parsed_name(response) do
    with 200 <- response.status,
         true <- is_map(response.body),
         true <- get_in(response.body, ["parsed"]),
         nil <- get_in(response.body, ["issues"]),
         {:ok, parsed_scientific_name} <- Map.fetch(response.body, "scientificName") do
      {:ok, parsed_scientific_name}
    else
      _ ->
        {:error,
         "[col_taxonomy] no valid scientific name found from CoL parse name api: #{inspect(response, limit: :infinity)}"}
    end
  end

  @spec lookup_species_by_name(String.t()) :: {:ok, any()} | {:error, String.t()}
  defp lookup_species_by_name(scientific_name) do
    case CoL.RestAPI.lookup_species_by_name(scientific_name) do
      {:ok, body} ->
        {:ok, body}

      {:error, error} ->
        {:error,
         "[col_taxonomy] Error while looking up species '#{scientific_name}' with CoL taxonomy api: #{inspect(error, limit: :infinity)}"}
    end
  end

  @spec validate_species(Req.Response.t()) :: {:ok, any()} | {:error, String.t()}
  defp validate_species(response) do
    with {:ok, response_body} <- validate({:response, response}),
         {:ok, species} <- validate({:body, response_body}),
         {:ok, scientific_name} <- validate({:scientific_name, species}),
         {:ok, classification} <- validate({:classification, species}) do
      encoded_species = %{
        tax_taxon_id: to_string(get_in(species, ["id"])),
        tax_scientific_name: scientific_name,
        tax_specific_epithet: get_in(species, ["usage", "name", "specificEpithet"]),
        tax_taxon_rank: get_in(species, ["usage", "name", "rank"]),
        tax_scientific_name_authorship: get_in(species, ["usage", "name", "authorship"])
      }

      encoded_species = reduce_species(classification, encoded_species)

      {:ok, encoded_species}
    else
      {:error, error} ->
        {:error, "[col_taxonomy] Invalid species encoding: #{inspect(error)}"}
    end
  end

  defp validate({:response, response}) do
    with 200 <- response.status,
         true <- is_map(response.body) do
      {:ok, response.body}
    else
      value ->
        {:error, "Failed to validate response. Value was: #{inspect(value)}. Response was: #{inspect(response)}"}
    end
  end

  defp validate({:body, response_body}) do
    with false <- is_nil(response_body),
         result = get_in(response_body, ["result"]),
         true <- is_list(result),
         false <- Enum.empty?(result),
         species = hd(result),
         false <- is_nil(species) do
      {:ok, species}
    else
      value ->
        {:error,
         "Failed to validate result list. Value was: #{inspect(value)}. Response Body was: #{inspect(response_body)}"}
    end
  end

  defp validate({:scientific_name, species}) do
    scientific_name = get_in(species, ["usage", "label"])

    with false <- is_nil(scientific_name),
         true <- scientific_name != "" do
      {:ok, scientific_name}
    else
      value ->
        {:error, "Failed to validate scientific name. Value was: #{inspect(value)}. Species was: #{inspect(species)}"}
    end
  end

  defp validate({:classification, species}) do
    classification = get_in(species, ["classification"])

    case is_list(classification) do
      true ->
        {:ok, classification}

      value ->
        {:error, "Failed to validate classification. Value was: #{inspect(value)}. Species was: #{inspect(species)}"}
    end
  end

  defp reduce_species(classification, encoded_species) do
    Enum.reduce(
      classification,
      encoded_species,
      fn class, encoded_species ->
        rank = get_in(class, ["rank"])
        name = get_in(class, ["name"])

        add_taxon_for_rank(encoded_species, rank, name)
      end
    )
  end

  @spec add_taxon_for_rank(map(), String.t(), String.t()) :: map()
  defp add_taxon_for_rank(acc, rank, name)

  defp add_taxon_for_rank(acc, rank, name)
       when rank in ["domain", "kingdom", "subkingdom", "phylum", "class", "subclass", "order", "family", "genus"] do
    Map.put(acc, String.to_atom("tax_#{rank}"), name)
  end

  defp add_taxon_for_rank(acc, _rank, _name), do: acc
end
