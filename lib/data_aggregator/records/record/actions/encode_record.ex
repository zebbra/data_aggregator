defmodule DataAggregator.Records.Encoding.Actions.EncodeRecord do
  @moduledoc """
  Encode Record with passed catalog. Returns the record itself after encoding.
  """
  use Ash.Resource.Actions.Implementation

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
    # track if it was failed and set accordingly afterwards
    previous_state = input.arguments.record.state
    record = set_encoding_state!(input.arguments.record)
    catalog = input.arguments.catalog

    Logger.debug("Encoding record with catalog: #{to_string(catalog)} started")

    # Process the encoding with the passed catalog
    # Strategy.encode/2 returns an EncodingResult.t() (encoded_record) and
    # update_state/1 returns an EncodingActionResult.t() (record)
    case record
         |> Strategy.encode(catalog)
         |> update_state(previous_state) do
      {:ok, record} ->
        Logger.debug(
          "[#{catalog}] Encoding for record #{record.id} with catalog: #{to_string(catalog)} finished with result: #{inspect(record)}"
        )

        {:ok, record}

      {:error, error, record} ->
        Logger.warning(
          "[#{catalog}] Encoding for record #{record.id} with catalog: #{to_string(catalog)} failed, due to: #{inspect(error)}"
        )

        {:ok, record}
    end
  end

  # set the state the processed record to `:encoded` or `:failed` and return it
  # keep track if a previous state was failed. In that case, set the state to `:failed`
  # even if the encoding was successful
  @spec update_state(EncodingResult.t(), atom()) :: EncodingActionResult.t()
  defp update_state(encoding_result, previous_state) do
    case encoding_result do
      {:ok, encoded_record} ->
        record = get_record(encoded_record)

        record =
          if previous_state === :failed,
            do: set_failed_state!(record),
            else: set_encoded_state!(record)

        {:ok, record}

      {:error, error, encoded_record} ->
        record = get_record(encoded_record)

        {:error, error, set_failed_state!(record)}
    end
  end

  # returns the encoded record from the result, or nil, if there was an error
  @spec get_record(EncodedRecord.t()) :: Record.t()
  defp get_record(encoded_record) do
    with_record = Ash.load!(encoded_record, [:record], lazy?: true)
    with_record.record
  end

  # update state of records to `:encoding`
  @spec set_encoding_state!(Record.t()) :: Record.t()
  defp set_encoding_state!(record) do
    Record.set_encoding!(record)
  end

  # update state of record to `:encoded`
  @spec set_encoded_state!(Record.t()) :: Record.t()
  defp set_encoded_state!(record) do
    Record.set_encoded!(record)
  end

  # update state of record to `:failed`
  @spec set_failed_state!(Record.t()) :: Record.t()
  defp set_failed_state!(record) do
    Record.set_encoding_failed!(record)
  end
end
