defmodule DataAggregator.Records.Encoding.Strategy.ConvertDatesStrategy do
  @moduledoc """
    Encode Records to convert and populate dates
  """

  import DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers,
    only: [
      all_dates_present?: 1,
      date_range?: 1,
      day_month_year_present?: 1,
      event_date_missing?: 1,
      no_dates_present?: 1,
      only_event_date_present?: 1,
      populate_day_month_year_range: 1,
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
    {:ok, process_encoded_record(encoded_record, ctx)}
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error, encoded_record}
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodedRecord.t()
  defp process_encoded_record(encoded_record, ctx) do
    encoded_record
    |> get_dates()
    |> convert_dates()
    |> Strategy.update_encoded_record(
      encoded_record,
      @output_attributes,
      ctx
    )
  end

  @spec convert_dates(map()) :: map()
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp convert_dates(dates) do
    cond do
      no_dates_present?(dates) ->
        # if no dates are present, return and proceed - nothing to convert then
        dates

      all_dates_present?(dates) or day_month_year_present?(dates) or event_date_missing?(dates) ->
        populate_event_date(dates)

      only_event_date_present?(dates) and not date_range?(dates) ->
        populate_day_month_year(dates)

      only_event_date_present?(dates) and date_range?(dates) ->
        populate_day_month_year_range(dates)

      true ->
        dates
    end
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[convert_dates] Error while encoding the encoded_record #{encoded_record_id}, failed to convert and santize date values: #{inspect(error)}"
    )
  end
end
