defmodule DataAggregatorWeb.Components.Internal.Stream do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [stream: 4]

  def stream_page(socket, page) do
    # For some reason, the results are appended to the stream in reverse order
    # if the stream does alredy exist. So we reverse the results in this case.
    results = if stream_exists?(socket), do: Enum.reverse(page.results), else: page.results
    page = Map.put(page, :results, [])

    results =
      Enum.map(results, fn result ->
        Map.put(
          result,
          :selected,
          socket.assigns.current_selected && result.id == socket.assigns.current_selected.id
        )
      end)

    socket
    |> assign(:page_meta, page)
    |> stream(:results, results, reset: true, at: 0, limit: 0)
  end

  def stream_results(socket, results) do
    # For some reason, the results are appended to the stream in reverse order
    # if the stream does alredy exist. So we reverse the results in this case.
    results = if stream_exists?(socket), do: Enum.reverse(results), else: results

    stream(socket, :results, results, reset: true, at: 0, limit: 0)
  end

  # Helper function to check if a stream exists
  defp stream_exists?(socket) do
    socket.assigns[:streams] != nil
  end
end
