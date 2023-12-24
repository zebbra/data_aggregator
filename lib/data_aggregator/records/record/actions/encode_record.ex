defmodule DataAggregator.Records.Encoding.Actions.EncodeRecord do
  @moduledoc """
  Encode Record with passed catalog
  """
  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
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

      # the record which will be encoded, whith it's state set to `:encoding`
      record_to_encode = set_encoding_state(record)

      # process the encoding with the passed catalog
      result = Strategy.encode(record_to_encode, catalog)

      # extract the record `Record.t()` from the encoding result
      encoded_record = get_record(result)

      # extract the failed record `Record.t()` from the encoding result
      failed_record = get_failed_record(result, record_to_encode)

      # extract the error `any()` from the encoding result
      error = get_error(result)

      # set the final encoding state of the processed record and pattern match the result for returning
      %{success: success, failed: failed} = set_final_state(failed_record, encoded_record)

      encoding_result = {:ok, %{error: error, encoded_record: success, failed_record: failed}}

      Logger.info(
        "Encoding for record #{record.id} with catalog: #{to_string(catalog)} finished with result: #{inspect(encoding_result)}}"
      )

      encoding_result
    catch
      error ->
        Logger.error(
          "Encoding for record #{record.id} with catalog: #{to_string(catalog)} failed, due to: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  # set the state the processed record to `:encoded` or `:encoding_failed` and return it
  @spec set_final_state(Record.t(), Record.t()) ::
          %{success: Record.t(), failed: Record.t()}
  defp set_final_state(failed_record, encoded_record) do
    case failed_record do
      nil -> %{success: set_encoded_state(encoded_record), failed: nil}
      _ -> %{success: nil, failed: set_encoding_failed_state(failed_record)}
    end
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

  # update state of record to `:encoding_failed`
  @spec set_encoding_failed_state(Record.t()) :: Record.t()
  defp set_encoding_failed_state(record) do
    Record.set_encoding_failed!(record)
  end

  # returns the error from the result, or nil, if there was no error
  @spec get_error({:error, any()} | {:ok, EncodedRecord.t()}) :: any() | nil
  defp get_error(result) do
    case result do
      {:error, error} -> error
      _ -> nil
    end
  end

  # returns the encoded record from the result, or nil, if there was an error
  @spec get_record({:error, any()} | {:ok, EncodedRecord.t()}) :: Record.t() | nil
  defp get_record(result) do
    case result do
      {:ok, encoded_record} ->
        with_record = Records.load!(encoded_record, [:record], lazy?: true)
        with_record.record

      {:error, _error} ->
        nil
    end
  end

  # returns the original record, to indicate, that it was failed to encode, and nil, if there was no error
  @spec get_failed_record({:error, any()} | {:ok, EncodedRecord.t()}, Record.t()) ::
          Record.t() | nil
  defp get_failed_record(result, record_to_encode) do
    case get_error(result) do
      nil -> nil
      _ -> record_to_encode
    end
  end
end
