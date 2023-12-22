defmodule DataAggregator.Records.Encoding.Actions.EncodeRecords do
  @moduledoc """
  Encode Records with configured catalogs
  """
  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Records.Record

  use Ash.Resource.Actions.Implementation

  require Logger

  @impl true
  def run(input, _opts, _context) do
    records = input.arguments.records

    try do
      encoding_result =
        Enum.map(Strategy.get_catalogs(), fn catalog ->
          Logger.info("Encoding records with catalog: #{to_string(catalog)}")

          records_to_encode = set_encoding_state(records)

          result = Strategy.encode(records_to_encode, catalog)

          errors = get_errors(result)

          encoded_records =
            Enum.map(get_records(result), fn encoded_record ->
              updated_encoded_record =
                EncodedRecord.update(encoded_record, Map.from_struct(encoded_record))
                |> Records.load!([:record])

              updated_encoded_record.record
            end)

          failed_records =
            get_failed_records(records_to_encode, encoded_records)

          %{success: success, failed: failed} = set_final_state(failed_records, encoded_records)

          %{errors: errors, successful_records: success, failed_records: failed}
        end)
        |> List.flatten()
        |> List.first()

      {:ok, encoding_result}
    catch
      error -> {:error, error}
    end
  end

  # set the state of all processed records to `:encoded` or `:encoding_failed` and return them
  @spec set_final_state([Record.t()], [Record.t()]) ::
          %{success: [Record.t()], failed: [Record.t()]}
  defp set_final_state(failed_records, encoded_records) do
    success = set_encoded_state(encoded_records)
    failed = set_encoding_failed_state(failed_records)

    %{success: success, failed: failed}
  end

  # get records that failed to be encoded
  @spec get_failed_records([Record.t()], [Record.t()]) :: [Record.t()]
  defp get_failed_records(records, encoded_records) do
    Enum.reject(records, fn record ->
      Enum.any?(encoded_records, fn encoded_record ->
        encoded_record.id == record.id
      end)
    end)
  end

  # update state of records to `:encoding`
  @spec set_encoding_state([Record.t()]) :: [Record.t()]
  defp set_encoding_state(records) do
    Enum.map(records, fn record ->
      Record.set_encoding!(record)
    end)
  end

  # update state of records to `:encoded`
  @spec set_encoded_state([Record.t()]) :: [Record.t()]
  defp set_encoded_state(records) do
    Enum.map(records, fn record ->
      Record.set_encoded!(record)
    end)
  end

  # update state of records to `:encoding_failed`
  @spec set_encoding_failed_state([Record.t()]) :: [Record.t()]
  defp set_encoding_failed_state(records) do
    Enum.map(records, fn record ->
      Record.set_encoding_failed!(record)
    end)
  end

  defp get_errors(result) do
    Enum.filter(result, fn record ->
      is_error(record)
    end)
    |> Enum.map(fn {:error, error} ->
      error
    end)
  end

  defp get_records(result) do
    Enum.filter(result, fn record ->
      !is_error(record)
    end)
    |> Enum.map(fn {:ok, record} ->
      record
    end)
  end

  defp is_error(result) do
    case result do
      {:error, _} -> true
      _ -> false
    end
  end
end
