defmodule DataAggregatorWeb.CollectionLive.Import.Components.Summary do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Import.Components
  import DataAggregatorWeb.CollectionLive.Import.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

  alias DataAggregator.Records.Import

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.stepper
        current={current_step(@action)}
        links={[nil, ~p"/collections/#{@collection}/imports/#{@import}/edit", nil]}
      />
      <.section_heading
        text={~t"Summary"m}
        description={~t"Please review the summary of your import."m}
        class="border-b border-black-white/10 py-4"
      >
        <:actions>
          <div class="flex items-center gap-x-2">
            <span class="text-sm"><%= ~t"State:"m %></span>
            <.import_state_badge import={@import} />
          </div>
        </:actions>
      </.section_heading>
      <div class="-mx-6 pb-4">
        <.list>
          <:item title={~t"File"m}>
            <div class="font-mono"><%= @import.attachment.filename %></div>
            <div class="text-base-content/60 mt-1 flex items-center gap-x-2 text-xs">
              <.attachment_download_badge attachment={@import.attachment} />
              <%= format_number(@import.rows_count) %> rows
            </div>
          </:item>
          <:item title={~t"Created at"m}>
            <%= format_datetime(@import.inserted_at) %>
          </:item>
          <:item title={~t"Rows"m}><%= format_number(@import.rows_count) %></:item>
        </.list>
      </div>

      <.section_heading text={~t"Mapping"m} size="md" />
      <div class="-mx-6 py-4">
        <div class="no-scrollbar overflow-x-auto">
          <.table id="import_mapping_table" rows={@import.mappings}>
            <:col :let={column} label={~t"Column"m}>
              <span :if={column.name} class="bg-base-200 inline-flex rounded px-2 py-1 text-xs">
                <%= column.name %>
              </span>
              <span :if={column.name == nil} class="text-error">
                <%= ~t"Mapping is invalid"m %>
              </span>
            </:col>
            <:col :let={column} label={~t"Mapped to"m}>
              <.attribute_badge name={column.mapped_to} mapped={column.mapped?} />
            </:col>
          </.table>
        </div>
      </div>

      <.section_heading text={~t"Unmapped columns"m} size="md" />
      <div class="py-4">
        <span
          :for={
            col <-
              @import.columns
              |> Enum.filter(&(&1.mapped? == false))
              |> Enum.map(& &1.name)
          }
          class="bg-base-200 mr-1 mb-1 inline-flex rounded px-2 py-1 text-xs"
        >
          <%= col %>
        </span>
      </div>

      <div class="modal-action">
        <.link
          patch={~p"/collections/#{@collection}/imports/#{@import}/edit"}
          type="button"
          class="btn btn-ghost"
        >
          <%= ~t"Back"m %>
        </.link>
        <button
          :if={@import.state == :pending}
          type="button"
          class="btn btn-primary"
          phx-click="import:run"
          phx-value-id={@import.id}
          phx-target={@myself}
        >
          <%= ~t"Run import"m %>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("import:run", _params, socket) do
    Import.enqueue_import!(socket.assigns.import)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Import started in background"m)
     |> push_event("submit:close", %{})
     |> push_patch(to: ~p"/collections/#{socket.assigns.collection}/imports")}
  end
end
