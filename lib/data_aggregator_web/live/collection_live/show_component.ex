defmodule DataAggregatorWeb.CollectionLive.ShowComponent do
  use DataAggregatorWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.sidebar>
        <:header>
          <.header id="collection-slideover" class="sticky top-0">
            <%= @collection.id %>
            <:subtitle>
              <%= ~t"This is an import record from your database."m %>
            </:subtitle>
          </.header>
        </:header>
        <.list>
          <:item title={~t"ID"m}><%= @collection.id %></:item>
          <:item title={~t"Name"m}><%= @collection.name %></:item>
        </.list>
        <:footer>
          <.link
            patch={~p"/collections/#{@collection}/show/edit"}
            phx-click={JS.push_focus()}
            class="focus-visible:outline-none"
          >
            <.button id="collection-modal-edit__button" class="inline-flex">
              <.icon name="hero-pencil-square-mini" class="mr-1.5 -ml-0.5 w-5 h-5" />
              <span><%= ~t"Edit Collection"m %></span>
            </.button>
          </.link>
        </:footer>
      </.sidebar>
    </div>
    """
  end
end
