defmodule DataAggregator.Records.ImageUpload.Calculations.MappedImages do
  @moduledoc """
  This `Ash.Resource.Calculation` calculates a list of filenames, of images that were mapped to a record. And the attribute on the mapped record that was used to map the image.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.Records.ImageUpload

  @impl true
  def load(_query, _opts, _context) do
    [images: [:record_id, :record, attachment: :filename]]
  end

  @impl Ash.Resource.Calculation
  def calculate(image_uploads, _opts, _ctx) do
    Enum.map(image_uploads, &mapped_images(&1))
  end

  defp mapped_images(%ImageUpload{images: images, mapping_identifier: mapping_identifier}) do
    images
    |> Enum.filter(&(&1.record_id != nil))
    |> Enum.map(fn image ->
      record = Ash.load!(image.record, mapping_identifier)
      {image.attachment.filename, Map.get(record, mapping_identifier)}
    end)
  end
end
