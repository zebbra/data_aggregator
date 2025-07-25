defmodule DataAggregator.Records.ImageUpload.Calculations.UnmappedImages do
  @moduledoc """
  This `Ash.Resource.Calculation` calculates a list of filenames of images that were not mapped to a record.
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
    Enum.map(image_uploads, &unmapped_images(&1))
  end

  defp unmapped_images(%ImageUpload{images: images}) do
    Enum.filter(images, &(&1.record_id == nil))
  end
end
