defmodule DataAggregator.Records.Validation.Workers.Validater do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Records.Validation.run/1` async.

  Used in `DataAggregator.Records.Validation.enqueue/1` (and tests) like:

  ```elixir
  {:ok, validation} =
    validation_id
    |> DataAggregator.Records.Validation.get_by_id!()
    |> DataAggregator.Records.Validation.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the validation to run
  * `collection_id` - the ID of the collection to validate

  """

  use Oban.Worker, queue: :validations, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Validation

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    with {:ok, validation} <- Validation.get_by_id(id, load: :collection, tenant: collection_id) do
      Logger.info("Running validation #{inspect(validation.id)} ...")
      Validation.run(validation, tenant: validation.collection)
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.validation_timeout() + to_timeout(minute: 1)
end
