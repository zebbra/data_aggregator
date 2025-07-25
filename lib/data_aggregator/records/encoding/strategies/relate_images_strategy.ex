defmodule DataAggregator.Records.Encoding.Strategy.RelateImagesStrategy do
  @moduledoc """
    Encode Records to relate with records images
  """

  import DataAggregator.Helpers, only: [maybe_performant_load_record: 3]

  import DataAggregator.Records.ImageUpload.Helpers,
    only: [construct_associated_media: 2]

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
  def apply_strategy(encoded_record, %{tenant: tenant} = ctx) do
    # Load the record and its images
    encoded_record = maybe_performant_load_record(encoded_record, tenant, images: :attachment)

    process_encoded_record(encoded_record, ctx)
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    new_associated_media =
      Enum.reduce(encoded_record.record.images, encoded_record.mte_associated_media, fn image, acc ->
        construct_associated_media(acc, image)
      end)

    {:ok,
     Strategy.update_encoded_record(
       %{mte_associated_media: new_associated_media},
       encoded_record,
       @output_attributes,
       ctx
     )}
  end
end
