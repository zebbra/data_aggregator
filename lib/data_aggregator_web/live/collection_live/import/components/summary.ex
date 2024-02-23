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
      <div class="space-y-8">
        <.heading
          title={~t"Summary"m}
          subtitle={~t"Please review the summary of your import."m}
          class="border-b border-black-white/10 py-4"
        >
          <:actions>
            <div class="flex items-center gap-x-2">
              <span class="text-sm"><%= ~t"State:"m %></span>
              <.import_state_badge import={@import} />
            </div>
          </:actions>
        </.heading>

        <div class="-mx-6">
          <.list>
            <:item title={~t"File"m}>
              <div class="font-mono"><%= @import.attachment.filename %></div>
              <div class="text-base-content/50 mt-1 flex items-center gap-x-2 text-xs">
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

        <div class="-mx-6">
          <div class="border-black-white/10 flex w-full items-center border-b px-6 pb-8 sm:px-8">
            <div class="min-w-0 flex-1">
              <h4 class="text-base-content font-bold">
                <%= ~t"Mapping"m %>
              </h4>
            </div>
          </div>

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
              <:col :let={column} label={~t"Mapped to"m} class="py-5">
                <.attribute_badge name={column.mapped_to} mapped={column.mapped?} />
              </:col>
            </.table>
          </div>

          <div class="px-6 lg:px-8">
            <.heading title={~t"Unmapped columns"m} size="sm" class="py-6 " />

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
        </div>
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
