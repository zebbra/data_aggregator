defmodule DataAggregator.Records.Encoding.Actions.EncodeRecord do
  @moduledoc """
  Encode Record with passed catalog
  """
  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingActionResult
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  @spec run(
          Ash.ActionInput.t(),
          opts :: Keyword.t(),
          any()
        ) :: EncodingActionResult.t()
  def run(input, _opts, _context) do
    record = set_encoding_state(input.arguments.record)
    catalog = input.arguments.catalog

    Logger.debug("Encoding record with catalog: #{to_string(catalog)} started")

    # process the encoding with the passed catalog
    case record
         |> Strategy.encode(catalog)
         |> update_state() do
      {:ok, encoded_record} ->
        Logger.debug(
          "Encoding for record #{record.id} with catalog: #{to_string(catalog)} finished with result: #{inspect(encoded_record)}"
        )

        {:ok, encoded_record}

      {:error, error} ->
        Logger.warning(
          "Encoding for record #{record.id} with catalog: #{to_string(catalog)} failed, due to: #{inspect(error)}"
        )

        set_failed_state!(record)

        {:error, error}
    end
  end

  # set the state the processed record to `:encoded` or `:failed` and return it
  @spec update_state(EncodingResult.t()) :: EncodingActionResult.t()
  defp update_state(encoding_result) do
    with {:ok, encoded_record} <- encoding_result do
      record = get_record(encoded_record)

      {:ok, set_encoded_state(record)}
    end
  end

  # returns the encoded record from the result, or nil, if there was an error
  @spec get_record(EncodedRecord.t()) :: Record.t()
  defp get_record(encoded_record) do
    with_record = Records.load!(encoded_record, [:record], lazy?: true)
    with_record.record
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
  @spec set_failed_state!(Record.t()) :: Record.t()
  defp set_failed_state!(record) do
    Record.set_encoding_failed!(record)
  end
end
