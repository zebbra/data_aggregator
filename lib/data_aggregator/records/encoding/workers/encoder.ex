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
  * `collection_id` - the ID of the collection to encode the record in
  * `user_id` - the ID of the user to run the encoding as (optional)

  ## Timeouts

  This worker uses the timeout

  """

  use Oban.Worker, queue: :encoders, max_attempts: 1

  alias DataAggregator.Accounts.User
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
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id, "user_id" => user_id}}) do
    with {:ok, record} <- Record.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(record, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    with {:ok, record} <- Record.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(record)
    end
  end

  defp perform_with_actor(record, actor \\ nil) do
    Logger.debug("Encoding for Record #{record.id} in progress...")

    case Enum.reduce_while(
           Catalog.get_catalogs(),
           {:ok, record},
           fn catalog, {:ok, acc} ->
             encode(catalog, record, acc, actor)
           end
         ) do
      {:ok, _} ->
        Record.update_validation_status(record, :unknown,
          actor: actor,
          authorize?: false,
          tenant: record.collection
        )

      {:error, error} ->
        {:error, error}
    end
  rescue
    e ->
      Logger.error(
        Exception.format(:error, e, __STACKTRACE__) <>
          " - " <>
          "Encoding for record #{inspect(record)} and collection #{inspect(record.collection)} failed unexpectedly."
      )

      reraise e, __STACKTRACE__
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.encode_timeout() + to_timeout(minute: 1)

  defp encode(catalog, record, acc, actor) do
    case Record.encode(acc, catalog,
           actor: actor,
           authorize?: false,
           tenant: record.collection
         ) do
      {:ok, record} ->
        {:cont, {:ok, record}}

      {:error, error} ->
        Logger.error(
          "Encoding for record #{inspect(record)} with catalog #{to_string(catalog)} failed with error #{inspect(error)}"
        )

        {:halt, {:error, error}}
    end
  end
end
