defmodule DataAggregatorWeb.ImportLive.ShowComponent do
  use DataAggregatorWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.sidebar>
        <:header>
          <.header id="import-slideover" class="sticky top-0">
            <%= @import.id %>
            <:subtitle>
              <%= ~t"This is an import record from your database."m %>
            </:subtitle>
          </.header>
        </:header>
        <.list>
          <:item title={~t"ID"m}><%= @import.id %></:item>
          <:item title={~t"URL"m}><%= @import.url %></:item>
        </.list>
        <:footer>
          <.link
            patch={~p"/imports/#{@import}/show/edit"}
            phx-click={JS.push_focus()}
            class="focus-visible:outline-none"
          >
            <.button id="import-modal-edit__button" class="inline-flex">
              <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
              <span><%= ~t"Edit import"m %></span>
            </.button>
          </.link>
        </:footer>
      </.sidebar>
    </div>
    """
  end
end
