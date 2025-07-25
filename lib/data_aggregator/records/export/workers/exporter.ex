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
  * `collection_id` - the ID of the collection to export

  """

  use Oban.Worker, queue: :exports, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Export

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    with {:ok, export} <- Export.get_by_id(id, load: :collection, tenant: collection_id) do
      Logger.info("Running export #{inspect(export.id)} ...")
      Export.run(export, tenant: export.collection)
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.export_timeout() + to_timeout(minute: 1)
end
