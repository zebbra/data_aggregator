defmodule DataAggregator.Records.ImageUpload.Workers.Mapper do
  @moduledoc """
    `Oban.Worker` to perform `DataAggregator.Records.ImageUpload.map/1` asynchronously.

  Usually this is not used directly, but rather through `DataAggregator.Records.ImageUpload.enqueue_mapping/1`:

  ```elixir
  {:ok, image_upload} =
    image_upload_id
    |> DataAggregator.Records.ImageUpload.get_by_id!()
    |> DataAggregator.Records.ImageUpload.enqueue_mapping()
  ```

  ## Arguments

  * `id` - the ID of the image upload to map
  * `user_id` - the ID of the user to run the mapping as (optional)

  ## Timeouts

  This worker uses the timeout
  """

  use Oban.Worker, queue: :mappings, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "user_id" => user_id}}) do
    with {:ok, image_upload} <- ImageUpload.get_by_id(id, load: :collection) do
      perform_with_actor(image_upload, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    with {:ok, image_upload} <- ImageUpload.get_by_id(id, load: :collection) do
      perform_with_actor(image_upload)
    end
  end

  defp perform_with_actor(image_upload, actor \\ nil) do
    Logger.debug("Mapping #{inspect(image_upload.id)} ...")

    ImageUpload.map(image_upload,
      actor: actor,
      authorize?: false,
      tenant: image_upload.collection
    )
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.mapping_timeout() + :timer.minutes(1)
end
