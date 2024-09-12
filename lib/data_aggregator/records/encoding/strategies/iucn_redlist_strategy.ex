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
  @input_attribute hd(Catalog.get_input_dwc_attributes(:gbif_iucn_redlist))

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes Catalog.get_output_attributes(:gbif_iucn_redlist)

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
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error, encoded_record}
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    taxon_id = encoded_record |> Map.get(@input_attribute, "") |> to_string()

    # early return if taxon_id is empty
    if taxon_id === "", do: raise("taxon_id is empty")

    with {:ok, response} <-
           taxon_id
           |> Gbif.RestAPI.get_iucn_redlist_category()
           |> ensure_response(taxon_id),
         :ok <- ensure_status(response) do
      if response.body === nil or response.body === "" do
        {:ok, encoded_record}
      else
        {:ok, Strategy.update_encoded_record(response.body, encoded_record, @output_attributes, ctx)}
      end
    else
      e ->
        {:error, error} = e
        {:error, error, encoded_record}
    end
  end

  defp ensure_response({:ok, response}, _), do: {:ok, response}

  defp ensure_response({:error, error}, taxon_id) do
    msg =
      "Error while iucn redlist status on gbif api using taxon_id: #{taxon_id}."

    Logger.warning("#{msg} #{inspect(error)}")

    {:error, msg}
  end

  defp ensure_status(response) when response.status == 200 or response.status == 204, do: :ok

  defp ensure_status(response) do
    msg = "Non 200 status code from gbif iucn redlist api."

    Logger.warning("#{msg} Message: #{inspect(response)}")

    {:error, msg}
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[gbif_iucn_redlist] Error while encoding the encoded_record #{encoded_record_id} with the gbif iucn redlist catalog: #{inspect(error)}"
    )
  end
end
