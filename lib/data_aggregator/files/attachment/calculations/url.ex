defmodule DataAggregator.Files.Attachment.Calculations.Url do
  @moduledoc """
  Ash calculation to generate a signed URL for a file using Waffle.
  """

  use Ash.Calculation

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  @url_args [:signed, :expires_in]

  @impl Ash.Calculation
  def calculate(attachments, opts \\ [], context \\ %{}) do
    Enum.map(attachments, &calculate_url(&1, opts, context))
  end

  defp calculate_url(%Attachment{filename: filename} = attachment, _opts, context) do
    {url_args, _context} = Map.split(context, @url_args)
    Store.url({filename, attachment}, Map.to_list(url_args))
  end
end
