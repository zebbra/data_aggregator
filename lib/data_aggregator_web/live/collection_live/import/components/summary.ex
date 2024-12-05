defmodule DataAggregatorWeb.CollectionLive.Import.Components.Summary do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Components
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1, can_run?: 1]

  alias DataAggregator.Records.Import

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title_class="!-mr-4 w-full">
        <.stepper
          current={current_step(@action)}
          links={[
            nil,
            build_path(~p"/collections/#{@collection}/imports/#{@import}/edit", @meta),
            nil
          ]}
        />
        <.section_heading
          text={~t"Summary"m}
          description={~t"Please review the summary of your import."m}
          class="mt-4"
        >
          <:actions>
            <div class="flex items-center gap-x-2">
              <span class="text-sm max-sm:hidden">{~t"State:"m}</span>
              <.import_state_badge import={@import} />
            </div>
          </:actions>
        </.section_heading>
      </.modal_header>

      <div class="h-full overflow-y-auto overflow-x-hidden px-6 py-1">
        <.list dense>
          <:item title={~t"File"m}>
            <.file_info attachment={@import.attachment} rows={@import.rows_count} badge />
          </:item>
          <:item title={~t"Created at"m}>
            {format_datetime(@import.inserted_at)}
          </:item>
          <:item title={~t"Rows"m}>{format_number(@import.rows_count)}</:item>
        </.list>

        <.table
          opts={[
            container_attrs: [
              class: "no-scrollbar overflow-x-auto py-4 -mx-6 lg:-mx-8"
            ]
          ]}
          id="import_mapping_table"
          items={@import.mappings}
        >
          <:caption>
            <.section_heading text={~t"Mapping"m} size="md" class="px-6 lg:px-8 text-left" />
          </:caption>
          <:col :let={column} label={~t"Column"m}>
            <span :if={column.name} class="bg-base-200 inline-flex rounded px-2 py-1 text-xs">
              {column.name}
            </span>
            <span :if={column.name == nil} class="text-error">
              {~t"Mapping is invalid"m}
            </span>
          </:col>
          <:col :let={column} label={~t"Mapped to"m}>
            <.attribute_badge column={column} />
          </:col>
        </.table>

        <.section_heading text={~t"Unmapped columns"m} size="md" />
        <div class="py-4">
          <span
            :for={
              col <-
                @import.columns
                |> Enum.filter(&(&1.mapped? == false))
                |> Enum.map(& &1.name)
            }
            class="bg-base-200 mr-2.5 mb-2 inline-flex rounded px-2 py-1 text-sm"
          >
            {col}
          </span>
        </div>
      </div>

      <.modal_footer id={@id}>
        <button
          disabled={@busy || can_run?(@import) == false}
          type="button"
          class="btn btn-primary"
          phx-click="import:run"
          phx-value-id={@import.id}
          phx-target={@myself}
        >
          {~t"Run import"m}
        </button>
        <.link
          patch={build_path(~p"/collections/#{@collection}/imports/#{@import}/edit", @meta)}
          type="button"
          class="btn btn-ghost"
        >
          {~t"Back"m}
        </.link>
      </.modal_footer>
    </div>
    """
  end

  @impl true
  def handle_event("import:run", _params, socket) do
    actor = get_actor(socket)

    case Import.enqueue_import(socket.assigns.import, %{started_by_id: actor.id}, actor: actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, ~t"Import started in background"m)
         |> close_and_redirect()}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, ~t"An import for this collection is already in process"m)
         |> close_and_redirect()}
    end
  end

  defp close_and_redirect(socket) do
    socket
    |> push_event("submit:close", %{})
    |> push_navigate(
      to:
        build_path(
          ~p"/collections/#{socket.assigns.collection}/imports",
          socket.assigns.meta
        )
    )
  end
end
