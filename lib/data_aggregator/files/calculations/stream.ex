defmodule DataAggregator.Files.Calculations.Stream do
  use Ash.Calculation

  alias DataAggregator.Files.Attachment

  @impl true
  def calculate(attachments, opts \\ [], context \\ %{}) do
    Enum.map(attachments, &stream(&1, opts, context))
  end

  defp stream(%Attachment{url: url}, _opts, _context) do
    {url, query} = parse_url_query(url)
    HTTPStream.get(url, query: query)
  end

  defp parse_url_query(url) do
    {:ok, uri} = URI.new(url)

    query = uri.query |> parse_query()
    url = %{uri | query: nil} |> URI.to_string()

    {url, query}
  end

  defp parse_query(nil), do: %{}
  defp parse_query(query), do: query |> URI.decode_query()
end
