defmodule DataAggregator.Files.Calculations.Url do
  @moduledoc """
  Ash calculation to generate a signed URL for a file using Waffle.
  """

  use Ash.Calculation

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  @url_args [:signed, :expires_in]

  @impl true
  def calculate(attachments, opts \\ [], context \\ %{}) do
    Enum.map(attachments, &calculate_url(&1, opts, context))
  end

  defp calculate_url(%Attachment{id: id, filename: filename}, _opts, context) do
    {url_args, _context} = context |> Map.split(@url_args)
    Store.url({filename, id}, url_args |> Map.to_list())
  end
end
