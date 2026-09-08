defmodule DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandler do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Records.ValidationResponse.run/1` async.

  Used in `DataAggregator.Records.ValidationResponse.enqueue/1` (and tests) like:

  ```elixir
  {:ok, validValidationResponseation} =
    validation_response_id
    |> DataAggregator.Records.ValidationResponse.get_by_id!()
    |> DataAggregator.Records.ValidationResponse.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the ValidationResponse to run

  """

  use Oban.Worker, queue: :validation_responses, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.ValidationResponse

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "user_id" => user_id}}) do
    with {:ok, validation_response} <-
           ValidationResponse.get_by_id(id) do
      Logger.info("Running ValidationResponse #{inspect(validation_response.id)} ...")
      perform_with_actor(validation_response, User.get_by_id!(user_id))
    end
  end

  defp perform_with_actor(validation_response, actor) do
    Logger.info("Running ValidationResponse #{inspect(validation_response.id)} ...")
    ValidationResponse.run(validation_response, actor: actor)
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.validation_response_timeout() + to_timeout(minute: 1)
end
