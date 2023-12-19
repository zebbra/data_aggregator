defmodule DataAggregator.Records.Encoding.Actions.EncodeRecord do
  @moduledoc """
  Encode Records with configured catalogs
  """
  alias DataAggregator.Records.Encoding.Strategy

  use Ash.Resource.Actions.Implementation

  require Logger

  @impl true
  def run(input, _opts, _context) do
    records_to_encode = input.arguments.records

    try do
      encoding_result =
        Enum.map(Strategy.get_catalogs(), fn catalog ->
          Logger.info("Encoding records with catalog: #{to_string(catalog)}")

          result = Strategy.encode(records_to_encode, catalog)

          errors = get_errors(result)

          records =
            get_records(result)

          %{errors: errors, records: records}
        end)
        |> List.flatten()
        |> List.first()

      {:ok, encoding_result}
    catch
      error -> {:error, error}
    end
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
