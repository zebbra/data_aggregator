defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Platform.Collection

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = Collection.get_by_id!(id)

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
    |> assign(:page_title, ~t"Import File"m)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.CollectionLive.FormComponent, {:saved, collection}},
        socket
      ) do
    {:noreply, assign(socket, :collection, collection)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:collections} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        <%= @collection.name %>
        <:actions>
          <.styled_link patch={~p"/collections/#{@collection}/import"} id="collection-modal__button">
            <.icon name="hero-plus-circle-mini" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <span class="sm:inline-block hidden"><%= ~t"Import File"m %></span>
          </.styled_link>
        </:actions>
      </.header>

      <.back navigate={~p"/collections"}>
        <%= ~t"Back"m %>
      </.back>

      <:portal>
        <.modal
          :if={@live_action == :import}
          id="collection-modal"
          on_cancel={JS.patch(~p"/collections/#{@collection}")}
        >
          <.live_component
            module={DataAggregatorWeb.CollectionLive.ImportFormComponent}
            id={@collection.id}
            icon="hero-plus-circle-mini"
            title={@page_title}
            action={:new}
            collection={@collection}
            patch={~p"/collections/#{@collection}"}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end
end
