defmodule DataAggregator.Records.Encoding.Strategy.AddInstitutionCodeStrategy do
  @moduledoc """
    Encode Records with the grscicoll institution data from its collectoin
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @output_attributes Catalog.get_output_attributes(:add_institution_code)

  @doc """
    lookup the grscicoll institution data from the collection and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    # Load the record and its collection
    encoded_record = Ash.load!(encoded_record, record: :collection)

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
    with {:ok, collection} when not is_nil(collection) <-
           extract_collection(encoded_record),
         {:ok, institution_key} <-
           extract_attribute_value(collection, :grscicoll_institution_key),
         {:ok, institution_code} <-
           extract_attribute_value(collection, :grscicoll_institution_code) do
      {:ok,
       Strategy.update_encoded_record(
         %{
           grscicoll_institution_key: institution_key,
           grscicoll_institution_code: institution_code
         },
         encoded_record,
         @output_attributes,
         ctx
       )}
    else
      {:error, _} ->
        {:error, "Could not extract grscicoll institution data from collection", encoded_record}
    end
  end

  @spec extract_collection(EncodedRecord.t()) :: {:ok, Collection.t()} | {:error, nil}
  defp extract_collection(encoded_record) do
    case encoded_record
         |> Map.get(:record)
         |> Map.get(:collection) do
      nil -> {:error, nil}
      collection -> {:ok, collection}
    end
  end

  @spec extract_attribute_value(Collection.t(), atom()) :: {:ok, any()} | {:error, nil}
  defp extract_attribute_value(collection, attribute) do
    case Map.get(collection, attribute) do
      nil -> {:error, nil}
      value -> {:ok, value}
    end
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(record_id, error) do
    Logger.warning("Error setting institution attributes for record #{record_id}: #{inspect(error)}")
  end
end
