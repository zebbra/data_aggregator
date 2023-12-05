defmodule DataAggregatorWeb.Components.Internal.Selection do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [stream_insert: 3]

  # Ensure the current selected record exists in the socket assigns
  def assign_current_selected(socket) do
    assign(socket, :current_selected, Map.get(socket.assigns, :current_selected, nil))
  end

  # Handle a select event from the client
  def handle_select(socket, new_selected) do
    old_selected = socket.assigns.current_selected

    if old_selected == new_selected do
      {:noreply, unselect_current_selected(socket)}
    else
      socket = assign(socket, :current_selected, new_selected)
      new_selected = Map.put(new_selected, :selected, true)

      if old_selected do
        old_selected = Map.put(old_selected, :selected, false)

        socket =
          socket
          |> stream_insert(:results, old_selected)
          |> stream_insert(:results, new_selected)

        {:noreply, socket}
      else
        {:noreply, stream_insert(socket, :results, new_selected)}
      end
    end
  end

  # Unselect the current selected record
  defp unselect_current_selected(socket) do
    selected = socket.assigns.current_selected

    if selected do
      selected = Map.put(selected, :selected, false)

      socket
      |> assign(:current_selected, nil)
      |> stream_insert(:results, selected)
    else
      socket
    end
  end
end
