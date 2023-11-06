defmodule DataAggregatorWeb.RecordLive.PreviewComponent do
  use DataAggregatorWeb, :html

  alias DataAggregator.Data.Record

  attr :record, Record, required: true
  attr :current_path_params, :string, required: true
  attr :live_action, :atom, required: true

  def preview(assigns) do
    ~H"""
    <aside class="xl:block xl:fixed xl:bottom-0 xl:right-0 xl:top-16 xl:w-96 xl:overflow-y-auto hidden">
      <.preview_content record={@record} current_path_params={@current_path_params} />
    </aside>

    <.slideover
      id="record-slideover"
      breakpoint="xl:hidden"
      show={false}
      on_cancel={JS.push("select", value: %{id: @record.id})}
    >
      <div class="flex flex-col h-full">
        <.preview_content
          record={@record}
          current_path_params={@current_path_params}
          slideover_id="record-slideover"
          modal_id="record-modal-edit__button"
        />
      </div>
    </.slideover>
    """
  end

  attr :record, Record, required: true
  attr :current_path_params, :string, required: true
  attr :slideover_id, :string, default: nil
  attr :modal_id, :string, default: nil

  defp preview_content(assigns) do
    ~H"""
    <.sidebar>
      <:header>
        <.header dialog_header_id={@slideover_id} class="sticky top-0">
          <%= @record.id %>
          <:subtitle>
            <%= ~t"This is a record from your database."m %>
          </:subtitle>
        </.header>
      </:header>
      <.list>
        <:item title={~t"ID"m}><%= @record.id %></:item>
        <:item title={~t"Material Entity ID"m}><%= @record.mte_material_entity_id %></:item>
        <:item title={~t"Scientific Name"m}><%= @record.tax_scientific_name %></:item>
      </.list>
      <:footer>
        <.button
          variant="secondary"
          class="inline-flex mr-2"
          phx-click={JS.push("select", value: %{id: @record.id})}
        >
          <span><%= ~t"Close"m %></span>
        </.button>
        <.styled_link patch={~p"/records/#{@record}/edit?#{@current_path_params}"} id={@modal_id}>
          <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
          <span><%= ~t"Edit Record"m %></span>
        </.styled_link>
      </:footer>
    </.sidebar>
    """
  end
end
