defmodule DataAggregator.Records.Encoding.Strategy.IUCNRedlistStrategy do
  @moduledoc """
    Encode Records with the gbif iucn redlist catalog api
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  # the input attributes are the attributes that will be used to query the catalog, so far we only use the tax_taxon_id
  @input_attributes Catalog.get_input_dwc_attributes(:iucn_redlist)

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes Catalog.get_output_attributes(:iucn_redlist)

  @doc """
    lookup the gbif iucn redlist api and return the encoded record
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
    with {:ok, scientific_name} <- ensure_params(encoded_record),
         {:ok, response} <-
           Gbif.RestAPI.get_species_by_scientific_name(scientific_name),
         {:ok, category} <- validate(response) do
      {:ok,
       Strategy.update_encoded_record(
         %{iucn_redlist_category: category},
         encoded_record,
         @output_attributes,
         ctx
       )}
    else
      {:error, error} ->
        {:error, error, encoded_record}
    end
  end

  defp ensure_params(encoded_record) do
    %{tax_scientific_name: scientific_name} =
      Map.take(encoded_record, @input_attributes)

    ensure_param(scientific_name)
  end

  defp ensure_param(param) when is_nil(param) or is_binary(param) == false or param == "",
    do: {:error, "tax_scientific_name is required to fetch IUCN Red List category"}

  defp ensure_param(param) do
    {:ok, param}
  end

  @spec validate(Req.Response.t() | tuple()) :: {:ok, any()} | {:error, String.t()}
  defp validate(_)

  defp validate(%Req.Response{} = response) do
    with {:ok, response} <- validate({:response, response}),
         {:ok, body} <- validate({:body, response}),
         {:ok, iucn_category} <- validate({:iucn_category, body}) do
      {:ok, iucn_category}
    else
      {:error, error} ->
        {:error, "Error validating encoding result. Error: #{inspect(error)}"}
    end
  end

  defp validate({:response, response}) do
    with true <- is_integer(response.status),
         true <- is_map(response.body) do
      {:ok, response}
    else
      value ->
        {:error, "Failed to validate response. Value was: #{inspect(value)}. Response was: #{inspect(response)}"}
    end
  end

  defp validate({:body, %Req.Response{body: nil} = response}),
    do: {:error, "Failed to validate response body. Body was: nil. Response was: #{inspect(response)}"}

  defp validate({:body, %Req.Response{status: 200, body: %{"diagnostics" => %{"matchType" => "NONE"}}}}),
    do: {:error, "Taxon not found in the Gbif V2 IUCN Redlist database"}

  defp validate({:body, %Req.Response{status: 200} = response}), do: {:ok, response.body}

  defp validate({:body, response}),
    do: {:error, "Unexpected response from Gbif V2 IUCN Redlist API. Response was: #{inspect(response)}"}

  defp validate({:iucn_category, body}) do
    additional_status = get_in(body, ["additionalStatus"])

    with false <- is_nil(additional_status),
         true <- is_list(additional_status),
         false <- Enum.empty?(additional_status),
         status = get_correct_status(additional_status),
         true <- is_map(status),
         category = get_in(status, ["statusCode"]),
         true <- is_binary(category) do
      {:ok, category}
    else
      value ->
        {:error,
         "Failed to validate IUCN category. Value was: #{inspect(value)}. additionalStatus were: #{inspect(additional_status)}"}
    end
  end

  defp get_correct_status(additional_status) do
    additional_status
    |> Enum.filter(&(&1["datasetAlias"] === "IUCN"))
    |> hd()
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[iucn_redlist] Error while encoding the encoded_record #{encoded_record_id} with the iucn redlist catalog: #{inspect(error)}"
    )
  end
end
