defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Headless.StatCard

  alias DataAggregator.Platform.Collection

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = DataAggregator.Platform.load!(Collection.get_by_id!(id), [:records_count])

    socket =
      socket
      |> assign(:collection, collection)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, ~t"Show Collection"m)
  end

  defp apply_action(socket, :import, _params) do
    socket
    |> assign(:page_title, ~t"Import Records"m)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.CollectionLive.ImportFormComponent, {:imported, import}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:import, import)
     |> push_navigate(to: ~p"/imports/#{import}")}
  end

  @impl true
  def handle_event("backto:collections", _, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/collections")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <.header class="top-16 sticky">
        <%= @collection.name %>

        <:actions>
          <.button
            variant="nav"
            class="rounded-md"
            aria-label={~t"Back to Collections"m}
            phx-click="backto:collections"
          >
            <.icon name="hero-arrow-left" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <%= ~t"Back to Collections"m %>
          </.button>
          <.styled_link patch={~p"/collections/#{@collection}/import"} id="collection-modal__button">
            <.icon name="hero-plus-circle-mini" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <span class="sm:inline-block hidden"><%= ~t"Import Records"m %></span>
          </.styled_link>
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <dl class="xl:grid-cols-4 sm:grid-cols-2 grid grid-cols-1 gap-5 mt-5">
          <.stat_card label={~t"Name"m} stat={@collection.name} />
          <.stat_card label={~t"Owner"m} stat={@collection.owner} />
          <.stat_card label={~t"Type"m} stat="OTHERS" />
          <.stat_card label={~t"Records in Collection"m} stat={@collection.records_count} />
          <.stat_card label={~t"Records Published"m} stat="0" />
          <.stat_card
            label={~t"Digitization Progress"m}
            stat={
              (100 / @collection.items_to_digitize * @collection.records_count)
              |> Decimal.from_float()
              |> Decimal.round(1)
            }
            stat_suffix="%"
          />
          <.stat_card label={~t"Expert Reviews"m} stat="0" />
          <.stat_card label={~t"Last Contribution"m} stat="13.11.2023" />
        </dl>
      </div>

      <.back navigate={~p"/collections"}>
        <%= ~t"Back"m %>
      </.back>

      <.modal
        :if={@live_action == :import}
        id="import-modal"
        on_cancel={JS.patch(~p"/collections/#{@collection}")}
      >
        <.live_component
          module={DataAggregatorWeb.CollectionLive.ImportFormComponent}
          id={"import_form-#{@collection.id}"}
          icon="hero-plus-circle-mini"
          title={@page_title}
          action={:new}
          collection={@collection}
          patch={~p"/collections/#{@collection}"}
        />
      </.modal>
    </main>
    """
  end
end
