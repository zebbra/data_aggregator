defmodule DataAggregatorWeb.ImportRecordLive.ShowComponent do
  use DataAggregatorWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <.sidebar>
        <:header>
          <.header id="import_record-slideover" class="sticky top-0">
            <%= @import_record.id %>
            <:subtitle>
              <%= ~t"This is an import_record from your database."m %>
            </:subtitle>
          </.header>
        </:header>
        <.list>
          <:item title={~t"ID"m}><%= @import_record.id %></:item>
          <:item title={~t"Unique Qualifier"m}><%= @import_record.unique_qualifier %></:item>
        </.list>
        <:footer>
          <.link
            patch={~p"/import_records/#{@import_record}/show/edit"}
            phx-click={JS.push_focus()}
            class="focus-visible:outline-none"
          >
            <.button id="import_record-modal-edit__button" class="inline-flex">
              <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
              <span><%= ~t"Edit import_record"m %></span>
            </.button>
          </.link>
        </:footer>
      </.sidebar>
    </div>
    """
  end
end
