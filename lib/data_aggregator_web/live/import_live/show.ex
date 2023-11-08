defmodule DataAggregatorWeb.ImportLive.Show do
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

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, ~t"Show Import"m)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <.header class="top-16 sticky">
        Schema of the import with ID '<%= @import.id %>' from the collection '<%= @import.collection.name %>'
        <:actions>
          <.styled_link patch={~p"/imports/#{@import}/mappings"} id="import-mapping__button">
            <.icon name="hero-table-cells-mini" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <span class="sm:inline-block hidden"><%= ~t"Map Columns"m %></span>
          </.styled_link>
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <ul
          role="list"
          class="dark:text-gray-400 px-7 2xl:w-4/12 xl:w-8/12 lg:w-8/12 md:w-8/12 sm:9/12 divide-slate-600 divide-dashed w-full mt-2 text-sm text-gray-500 divide-y"
        >
          <li class="gap-x-6 flex justify-between py-1 text-gray-200">
            <div class="gap-x-4 flex min-w-0">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-10">Column</p>
              </div>
            </div>
            <div class="gap-x-4 flex min-w-0">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-10">Type</p>
              </div>
            </div>
          </li>
          <%= for column <- @import.columns do %>
            <li class="gap-x-6 flex justify-between py-1">
              <div class="gap-x-4 flex min-w-0">
                <div class="flex-auto min-w-0">
                  <p class="text-sm leading-10"><%= column.name %></p>
                </div>
              </div>
              <div class="gap-x-4 flex min-w-0">
                <div class="flex-auto min-w-0">
                  <p class="text-sm leading-10"><%= column.type %></p>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
      <.back navigate={~p"/imports"}>
        <%= ~t"Back"m %>
      </.back>
    </main>
    """
  end
end
