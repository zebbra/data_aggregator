defmodule DataAggregator.Records.Encoding.Strategy.IUCNRedlistStrategy do
  @moduledoc """
    Encode Records with the gbif iucn redlist catalog api
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.IUCN
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
    with {:ok, genus, specific_epithet} <- ensure_params(encoded_record),
         {:ok, response} <- IUCN.RestAPI.get_iucn_redlist_category(genus, specific_epithet),
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
    %{tax_genus: genus, tax_specific_epithet: specific_epithet} =
      Map.take(encoded_record, @input_attributes)

    with {:ok, genus} <- ensure_param(genus),
         {:ok, specific_epithet} <- ensure_param(specific_epithet) do
      {:ok, genus, specific_epithet}
    end
  end

  defp ensure_param(param) when is_nil(param) or is_binary(param) == false or param == "",
    do: {:error, "tax_genus and tax_specific_epithet are required to fetch IUCN Red List category"}

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

  defp validate({:body, %Req.Response{status: 200} = response}), do: {:ok, response.body}

  defp validate({:body, %Req.Response{status: 404, body: %{"error" => "Not found"}}}),
    do: {:error, "Taxon not found in the IUCN Redlist database"}

  defp validate({:body, response}),
    do: {:error, "Unexpected response from IUCN Redlist API. Response was: #{inspect(response)}"}

  defp validate({:iucn_category, body}) do
    assessments = get_in(body, ["assessments"])

    with false <- is_nil(assessments),
         true <- is_list(assessments),
         false <- Enum.empty?(assessments),
         assessment = get_correct_assessment(assessments),
         true <- is_map(assessment),
         category = Map.get(assessment, "red_list_category_code"),
         true <- is_binary(category) do
      {:ok, category}
    else
      value ->
        {:error,
         "Failed to validate IUCN category. Value was: #{inspect(value)}. Assessments were: #{inspect(assessments)}"}
    end
  end

  defp get_correct_assessment(assessments) do
    assessments
    |> Enum.filter(&(&1["latest"] === true))
    |> hd()
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[iucn_redlist] Error while encoding the encoded_record #{encoded_record_id} with the iucn redlist catalog: #{inspect(error)}"
    )
  end
end
