defmodule DataAggregator.Records.ImageUpload.Calculations.MappedImages do
  @moduledoc """
  This `Ash.Resource.Calculation` calculates a list of filenames, of images that were mapped to a record. And the attribute on the mapped record that was used to map the image.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.Records.ImageUpload

  require Logger

  @impl true
  def load(_query, _opts, _context) do
    [images: [:record_id]]
  end

  @impl Ash.Resource.Calculation
  def calculate(image_uploads, _opts, _ctx) do
    Enum.map(image_uploads, &mapped_images(&1))
  end

  defp mapped_images(%ImageUpload{images: images}) do
    Enum.reject(images, &is_nil(&1.record_id))
  end
end
