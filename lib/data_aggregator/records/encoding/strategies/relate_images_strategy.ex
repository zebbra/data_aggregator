defmodule DataAggregator.Records.Encoding.Strategy.RelateImagesStrategy do
  @moduledoc """
    Encode Records to relate with records images
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @output_attributes Catalog.get_output_attributes(:relate_images)

  @doc """
    lookup the associated images from the record and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    # Load the record and its images
    encoded_record = Ash.load!(encoded_record, [record: [images: :attachment]], lazy?: true)

    process_encoded_record(encoded_record, ctx)
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    concatenated_images =
      Enum.map_join(encoded_record.record.images, " | ", & &1.attachment.url)

    concatenated_images =
      maybe_concatenate(encoded_record.mte_associated_media, concatenated_images)

    {:ok,
     Strategy.update_encoded_record(
       %{mte_associated_media: concatenated_images},
       encoded_record,
       @output_attributes,
       ctx
     )}
  end

  defp maybe_concatenate(associated_media, new_url) do
    case associated_media do
      "" -> new_url
      nil -> new_url
      _ -> "#{associated_media} | #{new_url}"
    end
  end
end
