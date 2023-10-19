defmodule DataAggregator.Preparations.Sort do
  use Ash.Resource.Preparation

  require Logger

  @impl true
  def prepare(query, _opts, _context) do
    sort = Ash.Query.get_argument(query, :sort)

    case Ash.Sort.parse_input(query.resource, sort) do
      {:ok, sort} ->
        query |> Ash.Query.sort(sort, prepend?: true)

      {:error, error} ->
        Logger.warning("Invalid sort: #{inspect(error)}")
        query
    end
  end
end
