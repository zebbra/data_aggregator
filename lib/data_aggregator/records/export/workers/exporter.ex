defmodule DataAggregator.Records.Export.Workers.Exporter do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Records.Export.run/1` async.

  Used in `DataAggregator.Records.Export.enqueue/1` (and tests) like:

  ```elixir
  {:ok, export} =
    export_id
    |> DataAggregator.Records.Export.get_by_id!()
    |> DataAggregator.Records.Export.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the export to run

  """

  use Oban.Worker, queue: :exports, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Export

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, export} <- Export.get_by_id(id) do
      Logger.info("Running export #{inspect(export.id)} ...")
      Export.run(export)
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.export_timeout() + :timer.minutes(1)
end
