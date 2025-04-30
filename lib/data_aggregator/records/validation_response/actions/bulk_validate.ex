defmodule DataAggregator.Records.ValidationResponse.Actions.BulkValidate do
  @moduledoc """
  Custom action to bulk validate a stream of rows using `DataAggregator.Records.AprovedRecord.validate/2`
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord

  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant}) do
    %{rows: rows} = input.arguments

    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.validation_response_batch_size() / max_concurrency)

    Logger.debug("Bulk validating records with batch size #{batch_size} (concurrency: #{max_concurrency}) ...")

    result =
      rows
      |> Stream.map(& &1)
      |> Ash.bulk_create!(ValidatedRecord, :validate,
        return_errors?: true,
        return_records?: true,
        max_concurrency: max_concurrency,
        batch_size: batch_size,
        tenant: tenant
      )

    {:ok, result}
  end
end
