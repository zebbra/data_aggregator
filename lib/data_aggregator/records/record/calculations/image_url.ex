defmodule DataAggregator.Records.Record.Calculations.ImageUrl do
  @moduledoc """
  This `Ash.Resource.Calculation` calculates the URL of an image.
  """

  use Ash.Resource.Calculation

  @impl Ash.Resource.Calculation
  def calculate(images, _opts, _ctx) do
    Enum.map(images, &construct_image_url(&1))
  end

  defp construct_image_url(%{collection_id: collection_id, id: id}) do
    System.get_env("BASE_URL") <>
      "/collections/" <> collection_id <> "/image_uploads/images/" <> id
  end
end
