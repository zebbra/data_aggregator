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
  """

  use Oban.Worker, queue: :imports

  alias DataAggregator.Records.Import

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, import} <- Import.get_by_id(id), do: import |> Import.run()
  end
end
