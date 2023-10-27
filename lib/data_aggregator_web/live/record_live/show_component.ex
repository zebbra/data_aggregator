defmodule DataAggregatorWeb.RecordLive.ShowComponent do
  use DataAggregatorWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.sidebar>
        <:header>
          <.header id="record-slideover" class="sticky top-0">
            <%= @record.id %>
            <:subtitle>
              <%= ~t"This is an import record from your database."m %>
            </:subtitle>
          </.header>
        </:header>
        <.list>
          <:item title={~t"ID"m}><%= @record.id %></:item>
          <:item title={~t"Unique Qualifier"m}><%= @record.unique_qualifier %></:item>
        </.list>
        <:footer>
          <.link
            patch={~p"/records/#{@record}/show/edit"}
            phx-click={JS.push_focus()}
            class="focus-visible:outline-none"
          >
            <.button id="record-modal-edit__button" class="inline-flex">
              <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
              <span><%= ~t"Edit Record"m %></span>
            </.button>
          </.link>
        </:footer>
      </.sidebar>
    </div>
    """
  end
end
