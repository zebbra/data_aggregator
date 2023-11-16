defmodule DataAggregator.Records.Import.Runner do
  @moduledoc """
  `Oban.Worker` to perform `DataAggregator.Records.Import.run/1` asynchronously.

  Usually this is not used directly, but rather through `DataAggregator.Records.Import.enqueue/1`:

  ```elixir
  {:ok, import} =
    import_id
    |> DataAggregator.Records.Import.get_by_id!()
    |> DataAggregator.Records.Import.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the import to run

  ## Timeouts

  This worker uses the timeout

  """

  use Oban.Worker, queue: :imports, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, import} <- Import.get_by_id(id) do
      Logger.info("Running import #{inspect(import)} ...")
      import |> Import.run()
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.import_timeout() + :timer.minutes(1)
end
