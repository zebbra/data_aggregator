defmodule DataAggregator.Platform.Publication.Export.Runner do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Plaform.Publication.Export.run/1` async.

  Used in `DataAggregator.Platform.Publication.Export.enqueue/1` (and tests) like:

  ```elixir
  {:ok, export} =
    export_id
    |> DataAggregator.Platform.Publication.Export.get_by_id!()
    |> DataAggregator.Platform.Publication.Export.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the export to run

  """

  use Oban.Worker, queue: :exports, max_attempts: 1

  alias DataAggregator.Platform.Publication.Export
  alias DataAggregator.Records

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, export} <- Export.get_by_id(id) do
      Logger.info("Running export #{inspect(export.id)} ...")
      export |> Export.run()
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.export_timeout() + :timer.minutes(1)
end
