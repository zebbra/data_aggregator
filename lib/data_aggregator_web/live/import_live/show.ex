defmodule DataAggregatorWeb.ImportLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.ImportRecord

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:import_record, ImportRecord.get_by_id!(id))}
  end

  defp page_title(:show), do: "Show Import Record"
  defp page_title(:edit), do: "Edit Import Record"
end
