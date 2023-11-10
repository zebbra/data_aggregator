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
      |> assign(:collection, import.collection)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, ~t"Show Import"m)
  end

  @impl true
  def handle_event("backto:collection", _params, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/collections/#{socket.assigns.collection}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:imports} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        Schema of your file for the collection '<%= @import.collection.name %>'
        <:actions>
          <.button
            variant="nav"
            class="rounded-md"
            aria-label={~t"Back to Collection"m}
            phx-click="backto:collection"
          >
            <.icon name="hero-arrow-left" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <%= ~t"Back to Collection"m %>
          </.button>
          <.styled_link patch={~p"/imports/#{@import}/mappings"} id="import-mapping__button">
            <.icon name="hero-check" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <span class="sm:inline-block hidden"><%= ~t"Map Columns"m %></span>
          </.styled_link>
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <ul
          role="list"
          class="dark:text-gray-400 px-7 2xl:w-6/12 xl:w-/12 lg:w-9/12 md:w-8/12 sm:9/12 divide-slate-600 divide-dashed w-full mt-2 text-sm text-gray-700 divide-y"
        >
          <li class="gap-x-6 dark:text-gray-200 flex justify-between py-1">
            <div class="gap-x-4 flex justify-start w-1/3">
              <p class="text-sm font-bold leading-10">Column</p>
            </div>

            <div class="gap-x-4 flex justify-end w-1/3">
              <p class="text-sm font-bold leading-10">Type</p>
            </div>
          </li>
          <%= for column <- @import.columns do %>
            <li class="gap-x-6 flex justify-between py-1">
              <div class="gap-x-4 flex justify-start w-1/3">
                <p class="text-sm leading-10"><%= column.name %></p>
              </div>
              <div class="gap-x-4 flex justify-end w-1/3">
                <p class="text-sm leading-10"><%= column.type %></p>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
      <.back navigate={~p"/collections/#{@collection}"}>
        <%= ~t"Back"m %>
      </.back>
    </.page>
    """
  end
end
