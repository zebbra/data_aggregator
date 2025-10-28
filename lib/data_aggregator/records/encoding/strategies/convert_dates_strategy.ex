defmodule DataAggregator.Records.Encoding.Strategy.ConvertDatesStrategy do
  @moduledoc """
    Encode Records to convert and populate dates
  """

  import DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers,
    only: [
      day_month_year_present?: 1,
      only_event_date_present?: 1,
      populate_day_month_year: 1,
      populate_event_date: 1,
      get_dates: 1
    ]

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @output_attributes Catalog.get_output_attributes(:convert_dates)

  @doc """
    converts the various date fields and returns the encoded record with the new date fields
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    case process_encoded_record(encoded_record, ctx) do
      {:ok, encoded_record} ->
        {:ok, encoded_record}

      {:error, error} ->
        handle_error(encoded_record.id, error)

        {:error, error, encoded_record}
    end
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) ::
          {:ok, EncodedRecord.t()} | {:error, String.t()}
  defp process_encoded_record(encoded_record, ctx) do
    dates = get_dates(encoded_record)

    case convert_dates(dates) do
      {:ok, converted_dates} ->
        {:ok, Strategy.update_encoded_record(converted_dates, encoded_record, @output_attributes, ctx)}

      {:invalid_event_date, error} ->
        handle_error(encoded_record.id, error)

        # set the event date to nil, because it is invalid
        EncodedRecord.update!(encoded_record, %{eve_event_date: nil})

        {:error, error}
    end
  end

  @spec convert_dates(map()) :: {:ok, map()} | {:invalid_event_date, String.t()}
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp convert_dates(dates) do
    cond do
      day_month_year_present?(dates) ->
        populate_event_date(dates)

      only_event_date_present?(dates) ->
        case populate_day_month_year(dates) do
          {:ok, dates} ->
            {:ok, dates}

          {:error, error} ->
            {:invalid_event_date, error}
        end

      true ->
        {:ok, dates}
    end
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[convert_dates] Error while encoding the encoded_record #{encoded_record_id}, failed to convert and santize date values: #{inspect(error)}"
    )
  end
end
