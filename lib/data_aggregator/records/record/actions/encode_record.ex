defmodule DataAggregator.Records.Encoding.Actions.EncodeRecord do
  @moduledoc """
  Encode Record with passed catalog
  """
  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Records.Record

  use Ash.Resource.Actions.Implementation

  require Logger

  @impl true
  @spec run(
          Ash.ActionInput.t(),
          opts :: Keyword.t(),
          any()
        ) ::
          {:ok, %{error: any(), encoded_record: Record.t(), failed_record: Record.t()}}
          | {:error, any()}
  def run(input, _opts, _context) do
    record = input.arguments.record
    catalog = input.arguments.catalog

    try do
      Logger.info("Encoding record with catalog: #{to_string(catalog)}")

      # process the encoding with the passed catalog
      encoding_result =
        set_encoding_state(record)
        |> Strategy.encode(catalog)
        |> update_state()

      Logger.info(
        "Encoding for record #{record.id} with catalog: #{to_string(catalog)} finished with result: #{inspect(encoding_result)}}"
      )

      encoding_result
    catch
      error ->
        Logger.error(
          "Encoding for record #{record.id} with catalog: #{to_string(catalog)} failed, due to: #{inspect(error)}"
        )

        store_error(record.id, catalog, error)
        |> set_failed_state()

        {:error, error}
    end
  end

  # set the state the processed record to `:encoded` or `:failed` and return it
  @spec update_state(EncodingResult.t()) ::
          {:ok, Record.t()} | {:error, any()}
  defp update_state(encoding_result) do
    case encoding_result do
      {:ok, encoded_record} ->
        record = get_record(encoded_record)
        {:ok, set_encoded_state(record)}

      {:error, error} ->
        throw(error)
    end
  end

  # returns the encoded record from the result, or nil, if there was an error
  @spec get_record(EncodedRecord.t()) ::
          Record.t()
  defp get_record(encoded_record) do
    with_record = Records.load!(encoded_record, [:record], lazy?: true)
    with_record.record
  end

  # store error to record
  @spec store_error(String.t(), atom(), any()) :: Record.t()
  defp store_error(record_id, catalog, error) do
    record = Record.get_by_id!(record_id)

    encoding_error = Map.put_new(%{}, catalog, error)

    errors = Map.put_new(record.errors || %{}, :encoding, encoding_error)

    Record.update!(record, %{errors: errors})
  end

  # update state of records to `:encoding`
  @spec set_encoding_state(Record.t()) :: Record.t()
  defp set_encoding_state(record) do
    Record.set_encoding!(record)
  end

  # update state of record to `:encoded`
  @spec set_encoded_state(Record.t()) :: Record.t()
  defp set_encoded_state(record) do
    Record.set_encoded!(record)
  end

  # update state of record to `:failed`
  @spec set_failed_state(Record.t()) :: Record.t()
  defp set_failed_state(record) do
    Record.set_failed!(record)
  end
end
