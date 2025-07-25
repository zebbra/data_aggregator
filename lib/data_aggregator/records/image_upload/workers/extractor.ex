defmodule DataAggregator.Records.ImageUpload.Workers.Extractor do
  @moduledoc """
    `Oban.Worker` to perform `DataAggregator.Records.ImageUpload.extract/1` asynchronously.

  Usually this is not used directly, but rather through `DataAggregator.Records.ImageUpload.enqueue_extraction/1`:

  ```elixir
  {:ok, image_upload} =
    image_upload_id
    |> DataAggregator.Records.ImageUpload.get_by_id!()
    |> DataAggregator.Records.ImageUpload.enqueue_extraction()
  ```

  ## Arguments

  * `id` - the ID of the image upload to extract
  * `collection_id` - the ID of the collection to extract the image upload for
  * `user_id` - the ID of the user to run the extraction as (optional)

  ## Timeouts

  This worker uses the timeout
  """

  use Oban.Worker, queue: :extractions, max_attempts: 1

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records
  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id, "user_id" => user_id}}) do
    with {:ok, image_upload} <-
           ImageUpload.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(image_upload, User.get_by_id!(user_id))
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    with {:ok, image_upload} <-
           ImageUpload.get_by_id(id, load: :collection, tenant: collection_id) do
      perform_with_actor(image_upload)
    end
  end

  defp perform_with_actor(image_upload, actor \\ nil) do
    Logger.debug("Extracting #{inspect(image_upload.id)} ...")

    ImageUpload.extract(image_upload,
      actor: actor,
      authorize?: false,
      tenant: image_upload.collection
    )
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.extraction_timeout() + to_timeout(minute: 1)
end
