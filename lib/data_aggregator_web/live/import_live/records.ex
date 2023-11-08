defmodule DataAggregatorWeb.ImportLive.Records do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Platform.Import

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    import = DataAggregator.Platform.load!(Import.get_by_id!(id), collection: [:id, :name])

    socket =
      socket
      |> assign(:import, import)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show_records, _params) do
    socket
    |> assign(:page_title, ~t"Imported Records"m)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <.header class="top-16 sticky">
        The following records were imported to your collection '<%= @import.collection.name %>'
        <:actions></:actions>
      </.header>

      <div class="justify-items-center grid">
        <ul
          role="list"
          class="dark:text-gray-400 px-7 2xl:w-4/12 xl:w-8/12 lg:w-8/12 md:w-8/12 sm:9/12 divide-slate-600 divide-dashed w-full mt-2 text-sm text-gray-500 divide-y"
        >
          --- list here the imported records ---
        </ul>
      </div>
      <.back navigate={~p"/imports"}>
        <%= ~t"Back"m %>
      </.back>
    </main>
    """
  end
end
