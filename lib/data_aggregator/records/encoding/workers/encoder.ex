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

  use Oban.Worker, queue: :encoders, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @doc """
    process the encoding with the passed catalog.
    do as long as there is no error, then stop and return.
    if there is no error, a success tuple is returned containing the encoded record
  """
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, record} <- Record.get_by_id(id) do
      Logger.debug("Encoding for Record #{record.id} in progress...")

      Enum.reduce_while(
        Catalog.get_catalogs(),
        {:ok, record},
        fn catalog, {:ok, acc} ->
          case Record.encode(acc, catalog) do
            {:ok, encoded_record} ->
              {:cont, {:ok, encoded_record}}

            {:error, error} ->
              {:halt, {:error, error}}
          end
        end
      )
    end
  rescue
    error ->
      Logger.error("Error encoding Record #{id}: #{inspect(error)}")
      {:error, error}
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.encode_timeout() + :timer.minutes(1)
end
