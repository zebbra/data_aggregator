defmodule DataAggregator.Records.Import.Workers.Importer do
  @moduledoc """
  `Oban.Worker` to perform `DataAggregator.Records.Import.import/1` asynchronously.

  Usually this is not used directly, but rather through `DataAggregator.Records.Import.enqueue_import/1`:

  ```elixir
  {:ok, import} =
    import_id
    |> DataAggregator.Records.Import.get_by_id!()
    |> DataAggregator.Records.Import.enqueue_import()
  ```

  ## Arguments

  * `id` - the ID of the import to run
  * `collection_id` - the ID of the collection to import
  * `user_id` - the ID of the user to run the import as (optional)

  ## Timeouts

  This worker uses the timeout

  """

  use Oban.Worker, queue: :imports, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id, "user_id" => user_id}}) do
    with {:ok, import} <- Import.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(import, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    with {:ok, import} <- Import.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(import)
    end
  end

  defp perform_with_actor(import, actor \\ nil) do
    Logger.debug("Importing #{inspect(import.id)} ...")
    Import.import(import, actor: actor, authorize?: false, tenant: import.collection)
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.import_timeout() + to_timeout(minute: 1)
end
