defmodule DataAggregatorWeb.ImportRecordLive.PreviewComponent do
  use DataAggregatorWeb, :html

  alias DataAggregator.Imports.ImportRecord

  attr :import_record, ImportRecord, required: true
  attr :current_path_params, :string, required: true
  attr :live_action, :atom, required: true

  def preview(assigns) do
    ~H"""
    <aside class="xl:block xl:fixed xl:bottom-0 xl:right-0 xl:top-16 xl:w-96 xl:overflow-y-auto hidden">
      <.preview_content import_record={@import_record} current_path_params={@current_path_params} />
    </aside>

    <.slideover
      id="import-record-slideover"
      breakpoint="xl:hidden"
      show={false}
      on_cancel={JS.push("select", value: %{id: @import_record.id})}
    >
      <div class="flex flex-col h-full">
        <.preview_content
          import_record={@import_record}
          current_path_params={@current_path_params}
          slideover_id="import-record-slideover"
          modal_id="import-record-modal-edit__button"
        />
      </div>
    </.slideover>
    """
  end

  attr :import_record, ImportRecord, required: true
  attr :current_path_params, :string, required: true
  attr :slideover_id, :string, default: nil
  attr :modal_id, :string, default: nil

  defp preview_content(assigns) do
    ~H"""
    <.sidebar>
      <:header>
        <.header id={@slideover_id} class="sticky top-0">
          <%= @import_record.id %>
          <:subtitle>
            <%= ~t"This is an import record from your database."m %>
          </:subtitle>
        </.header>
      </:header>
      <.list>
        <:item title={~t"ID"m}><%= @import_record.id %></:item>
        <:item title={~t"Unique Qualifier"m}><%= @import_record.unique_qualifier %></:item>
      </.list>
      <:footer>
        <.button
          variant="secondary"
          class="inline-flex mr-2"
          phx-click={JS.push("select", value: %{id: @import_record.id})}
        >
          <span><%= ~t"Close"m %></span>
        </.button>
        <.styled_link
          patch={~p"/import_records/#{@import_record}/edit?#{@current_path_params}"}
          id={@modal_id}
        >
          <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
          <span><%= ~t"Edit Import Record"m %></span>
        </.styled_link>
      </:footer>
    </.sidebar>
    """
  end
end
