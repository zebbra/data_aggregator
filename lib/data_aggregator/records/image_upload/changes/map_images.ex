defmodule DataAggregator.Records.ImageUpload.Changes.MapImages do
  @moduledoc """
  Changeset hook to map images from the image upload to the collections records.
  """
  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Resource.Change.Context
  alias DataAggregator.Records
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &map_images(&1, ctx))
  end

  defp map_images(%Changeset{data: image_upload} = changeset, ctx) do
    Logger.info("Mapping images for #{inspect(image_upload.id)} ...")

    image_upload =
      Ash.load!(image_upload, [:collection, images: :attachment], lazy?: true)

    total_images = length(image_upload.images)

    changeset =
      set_unmapped_images_count(changeset, total_images)

    changeset =
      Record
      |> Ash.Query.set_tenant(image_upload.collection)
      |> Ash.Query.filter(collection_id == ^image_upload.collection_id)
      |> Ash.stream!()
      |> Stream.map(&process_record(&1, image_upload, ctx))
      |> reduce_image_mapping_results(changeset, total_images)
      |> error_if_no_images_mapped()

    mapped_images_count = Changeset.get_attribute(changeset, :mapped_images_count)

    # Update the image upload with the number of unmapped images
    changeset =
      set_unmapped_images_count(changeset, total_images - mapped_images_count)

    # Update the image upload with the number of processed images
    set_processed_images_count(changeset, total_images)
  end

  @spec process_record(Record.t(), ImageUpload.t(), Context.t()) :: pos_integer()
  defp process_record(record, image_upload, ctx) do
    chunk_size = Records.image_processing_batch_size()

    # Process all image chunks for the current record
    # and reduce the results to `amount_of_mapped_images` for this record
    mapped_images =
      image_upload.images
      |> Stream.chunk_every(chunk_size)
      |> Enum.with_index()
      |> Stream.map(&process_image_chunk(&1, record, image_upload, ctx))
      |> Enum.reduce_while(0, fn mapped, acc_mapped ->
        if mapped >= length(image_upload.images) do
          # If all images are mapped, stop processing further chunks
          {:halt, mapped + acc_mapped}
        else
          # Use the latest processed_record_segment as the updated record state
          {:cont, mapped + acc_mapped}
        end
      end)

    mapped_images
  end

  @spec process_image_chunk(
          {[Record.Image.t()], pos_integer()},
          Record.t(),
          ImageUpload.t(),
          Context.t()
        ) :: pos_integer()
  defp process_image_chunk({images_chunk, index}, record, image_upload, %{actor: actor, tenant: tenant}) do
    Logger.info("Processing images chunk ##{index} with #{length(images_chunk)} images")

    # Process each image in the chunks asynchronously and check if it matches the record
    mapped_images =
      images_chunk
      |> Task.async_stream(&{&1, matching_image?(record, &1, image_upload.mapping_identifier)},
        timeout: to_timeout(second: 30)
      )
      |> Enum.reduce([], fn
        {:ok, {image, true}}, mapped -> [image | mapped]
        {:ok, {_image, false}}, mapped -> mapped
      end)

    _record =
      Record.add_images!(record, Enum.reverse(mapped_images),
        actor: actor,
        authorize?: false,
        tenant: tenant
      )

    length(mapped_images)
  end

  @spec matching_image?(Record.t(), Record.Image.t(), String.t()) ::
          boolean()
  defp matching_image?(record, image, identifier) do
    parts = String.split(image.attachment.filename, "_")

    # in case the there is no - in the name split for the .
    part_to_match =
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

    part_to_match == Map.get(record, identifier)
  end

  defp reduce_image_mapping_results(results, changeset, total_images) do
    Enum.reduce_while(results, changeset, fn
      mapped, changeset ->
        Logger.info("Mapped #{mapped} images in this batch")

        changeset = report_process(changeset, mapped)

        current_mapped = Changeset.get_attribute(changeset, :mapped_images_count)

        # If all images are mapped, stop processing further, to save resources and time
        if current_mapped >= total_images do
          {:halt, changeset}
        else
          {:cont, changeset}
        end
    end)
  end

  @spec report_process(Changeset.t(), pos_integer()) ::
          Changeset.t()
  defp report_process(changeset, mapped) do
    Logger.debug("Batch successful (#{mapped} mapped)")

    %Changeset{data: image_upload} = changeset

    add_progress = fn ->
      ImageUpload.add_mapping_progress!(image_upload, mapped)
    end

    image_upload =
      if Records.execute_async?() do
        add_progress |> Task.async() |> Task.await(to_timeout(second: 30))
      else
        add_progress.()
      end

    %{changeset | data: image_upload}
  end

  defp set_unmapped_images_count(changeset, count) do
    Logger.debug("Set :unmapped_images_count (#{count})")

    %Changeset{data: image_upload} = changeset

    set_unmapped_count = fn ->
      ImageUpload.update!(image_upload, %{unmapped_images_count: count})
    end

    image_upload =
      if Records.execute_async?() do
        set_unmapped_count |> Task.async() |> Task.await(to_timeout(second: 30))
      else
        set_unmapped_count.()
      end

    %{changeset | data: image_upload}
  end

  defp set_processed_images_count(changeset, count) do
    Logger.debug("Set :general_mapping_progress_count (#{count})")

    %Changeset{data: image_upload} = changeset

    set_images_count = fn ->
      ImageUpload.update!(image_upload, %{general_mapping_progress_count: count})
    end

    image_upload =
      if Records.execute_async?() do
        set_images_count |> Task.async() |> Task.await(to_timeout(second: 30))
      else
        set_images_count.()
      end

    %{changeset | data: image_upload}
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
end
