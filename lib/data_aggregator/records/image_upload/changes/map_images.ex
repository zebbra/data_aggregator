defmodule DataAggregator.Records.ImageUpload.Changes.MapImages do
  @moduledoc """
  Changeset hook to map images from the image upload to the collections records.
  """
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Counter
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Helpers
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &maybe_map_images(&1))
  end

  # if the mapping identifier is not supported, we abort, and add an error
  defp maybe_map_images(%Changeset{data: image_upload} = changeset) do
    if image_upload.mapping_identifier in Map.keys(Helpers.mapping_identifiers()) do
      # Map the images to the records
      {time, result} =
        :timer.tc(
          fn -> map_images(changeset) end,
          :millisecond
        )

      Logger.info("Mapping images took #{time} ms")

      result
    else
      Changeset.add_error(
        changeset,
        "The mapping identifier #{image_upload.mapping_identifier} is not supported. Must be one of: #{inspect(Helpers.mapping_identifiers())}"
      )
    end
  end

  defp map_images(%Changeset{data: image_upload} = changeset) do
    Logger.info("Mapping images for #{inspect(image_upload.id)} ...")

    query = Helpers.compose_mappable_image_query(image_upload)

    total_images = Helpers.count_mappable_images(query)

    {:ok, counter_operations} =
      Counter.start(&ImageUpload.add_current_mapping_operations_count!(image_upload, &1))

    {:ok, counter_process} =
      Counter.start(&ImageUpload.add_mapping_progress!(image_upload, &1))

    # we have to stream the images, otherwise we bload the memory
    query
    |> Ash.stream!()
    |> Stream.map(&map_image(&1, image_upload))
    |> reduce_image_mapping_results(changeset, counter_operations, counter_process)
    |> error_if_no_images_mapped()

    Counter.stop(counter_operations)
    Counter.stop(counter_process)

    mapped_images_count = Changeset.get_attribute(changeset, :mapped_images_count)

    Helpers.update_counts(changeset, mapped_images_count, total_images)
  end

  # Maps the image to the record, returns 1 if successful mapped, 0 if not
  @spec map_image(Record.Image.t(), ImageUpload.t()) :: pos_integer()
  defp map_image(image, image_upload) do
    image = Ash.load!(image, [:attachment], lazy?: true)

    parts = String.split(image.attachment.filename, "_")

    # in case the there is no _ in the name split for the .
    identified_value =
      if length(parts) == 1 do
        parts
        |> List.first()
        |> String.split(".")

        # remove the file extension
        |> List.delete_at(-1)
        |> Enum.join(".")
      else
        List.first(parts)
      end

    case get_one_record(image_upload, identified_value) do
      {:ok, nil} ->
        Logger.debug(
          "Image #{image.attachment.filename} not mapped. No record found for identifier #{image_upload.mapping_identifier} and value #{identified_value}"
        )

        0

      {:ok, record} ->
        # If the record is found, add the image to the record
        Logger.debug("Image #{image.attachment.filename} mapped to record #{record.id}")

        # Add the image to the record
        Record.add_images!(record, [image], authorize?: false, tenant: image_upload.collection)

        1

      {:error, reason} ->
        Logger.error("Error while mapping image #{image.attachment.filename}: #{reason}")

        0
    end
  end

  defp reduce_image_mapping_results(results, changeset, counter_operations, counter_process) do
    Enum.reduce(results, changeset, fn
      mapped, changeset ->
        Counter.increment(counter_operations, 1)
        Counter.increment(counter_process, mapped)

        %Changeset{data: image_upload} = changeset

        image_upload = %{
          image_upload
          | mapped_images_count: image_upload.mapped_images_count + mapped,
            unmapped_images_count: image_upload.unmapped_images_count - mapped,
            current_mapping_operations_count: image_upload.current_mapping_operations_count + 1
        }

        changeset = %{changeset | data: image_upload}

        changeset
    end)
  end

  defp error_if_no_images_mapped(changeset) do
    %Changeset{data: image_upload} = changeset

    if image_upload.mapped_images_count == 0 do
      add_error(changeset, "No images mapped.")
    else
      changeset
    end
  end

  defp add_error(changeset, error) do
    Logger.warning("Error mapping images to records: #{inspect(error)}")

    Changeset.add_error(changeset, error)
  end

  defp get_one_record(image_upload, value) do
    Record
    |> Ash.Query.set_tenant(image_upload.collection)
    |> Ash.Query.filter(^ref(image_upload.mapping_identifier) == ^value)
    |> Ash.read_one()
  end
end
