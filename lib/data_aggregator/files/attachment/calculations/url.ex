defmodule DataAggregator.Files.Attachment.Calculations.Url do
  @moduledoc """
  Ash calculation to generate a signed URL for a file using Waffle.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Store

  @url_args [:signed, :expires_in]

  @impl Ash.Resource.Calculation
  def calculate(attachments, _opts, %{arguments: arguments}) do
    Enum.map(attachments, &calculate_url(&1, arguments))
  end

  defp calculate_url(%Attachment{filename: filename} = attachment, arguments) do
    {url_args, _arguments} = Map.split(arguments, @url_args)
    Store.url({filename, attachment}, Map.to_list(url_args))
  end
end
