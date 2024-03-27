defmodule DataAggregator.Records.Publication.Runner do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Records.Publication.run/1` async.

  Used in `DataAggregator.Records.Publication.enqueue/1` (and tests) like:

  ```elixir
  {:ok, publication} =
    publication_id
    |> DataAggregator.Records.Publication.get_by_id!()
    |> DataAggregator.Records.Publication.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the publication to run

  """

  use Oban.Worker, queue: :publications, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Publication

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, publication} <- Publication.get_by_id(id) do
      Logger.info("Running publication #{inspect(publication.id)} ...")
      Publication.run(publication)
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.export_timeout() + :timer.minutes(1)
end
