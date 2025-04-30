defmodule DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Records.ValidationRequest.run/1` async.

  Used in `DataAggregator.Records.ValidationRequest.enqueue/1` (and tests) like:

  ```elixir
  {:ok, validation_request} =
    validation_request_id
    |> DataAggregator.Records.ValidationRequest.get_by_id!()
    |> DataAggregator.Records.ValidationRequest.enqueue()
  ```
  ## Arguments
  * `id` - the ID of the ValidationRequest to run
  * `collection_id` - the ID of the collection to validate
  * `user_id` - the ID of the user to run the ValidationRequest as (optional)
  """

  use Oban.Worker, queue: :validation_requests, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.ValidationRequest

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id, "user_id" => user_id}}) do
    with {:ok, validation_request} <-
           ValidationRequest.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(validation_request, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    with {:ok, validation_request} <-
           ValidationRequest.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(validation_request)
    end
  end

  defp perform_with_actor(validation_request, actor \\ nil) do
    Logger.info("Running ValidationRequest #{inspect(validation_request.id)} ...")

    ValidationRequest.run(validation_request,
      actor: actor,
      authorize?: false,
      tenant: validation_request.collection
    )
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.validation_request_timeout() + to_timeout(minute: 1)
end
