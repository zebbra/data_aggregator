defmodule DataAggregator.Records.Encoding.Strategy.IUCNRedlistStrategy do
  @moduledoc """
    Encode Records with the gbif iucn redlist catalog api
  """

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
  @spec apply_strategy(EncodedRecord.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record) do
    case process_encoded_record(encoded_record) do
      {:ok, encoded_record} ->
        {:ok, encoded_record}

      {:error, error} ->
        handle_error(encoded_record.id, error)

        {:error, error}
    end
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error}
  end

  @spec process_encoded_record(EncodedRecord.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record) do
    taxon_id = encoded_record |> Map.get(@input_attribute, "") |> to_string()

    with {:ok, response} <-
           taxon_id
           |> Gbif.RestAPI.get_iucn_redlist_category()
           |> ensure_response(taxon_id),
         :ok <- ensure_status(response) do
      if response.body === nil or response.body === "" do
        {:ok, encoded_record}
      else
        {:ok, Strategy.update_encoded_record(response.body, encoded_record, @output_attributes)}
      end
    end
  end

  defp ensure_response({:ok, response}, _), do: {:ok, response}

  defp ensure_response({:error, error}, taxon_id) do
    msg =
      "Error while iucn redlist status on gbif api using taxon_id: #{taxon_id}. #{inspect(error)}"

    Logger.error(msg)

    {:error, msg}
  end

  defp ensure_status(response) when response.status == 200 or response.status == 204, do: :ok

  defp ensure_status(response) do
    msg = "Non 200 status code from gbif iucn redlist api with message: #{inspect(response)}"

    Logger.error(msg)

    {:error, msg}
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(record_id, error) do
    Logger.warning("Error while encoding the record #{record_id} with the gbif iucn redlist catalog: #{inspect(error)}")
  end
end
