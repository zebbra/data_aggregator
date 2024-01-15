defmodule DataAggregator.Records.Record.Workers.Encoder do
  @moduledoc """
  `Oban.Worker` to perform `DataAggregator.Records.Record.encode/2` asynchronously.

  Usually this is not used directly, but rather through `DataAggregator.Records.Record.enqueue_encoder/1`:

  ```elixir
  {:ok, record} =
    record_id
    |> DataAggregator.Records.Record.get_by_id!()
    |> DataAggregator.Records.Record.enqueue_encoder()
  ```

  ## Arguments

  * `id` - the ID of the record to encode during the run

  ## Timeouts

  This worker uses the timeout

  """

  alias DataAggregator.Records.Record
  use Oban.Worker, queue: :encoders, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, record} <- Record.get_by_id(id) do
      Logger.info("Encoding for Record #{inspect(record.id)} in progress...")

      with {:ok, record} <- Record.encode(record, :gbif_taxonomy),
           {:ok, record} <- Record.encode(record, :swiss_species) do
        {:ok, record}
      else
        {:error, error} -> {:error, error}
      end
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.encode_timeout() + :timer.minutes(1)
end
