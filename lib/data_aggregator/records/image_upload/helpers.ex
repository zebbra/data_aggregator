defmodule DataAggregator.Records.ImageUpload.Helpers do
  @moduledoc false

  @accepted_image_extensions ~w(.jpg .jpeg .png .bmp .tiff .svg .webp)
  def accepted_image_extensions, do: @accepted_image_extensions

  @max_image_size 5_242_880
  def max_image_size, do: @max_image_size
end
