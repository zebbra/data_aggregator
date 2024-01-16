defmodule DataAggregatorWeb.ImportLive.Show do
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.ImportLive.Components

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Import
  alias DataAggregatorWeb.ImportLive.Components.MappingForm
  alias Phoenix.LiveView.Socket

  require Logger

  @load [
    :collection,
    :import_progress,
    :validation_progress,
    :rows_valid_ratio,
    :rows_validated_count,
    :mappings,
    :missing_mappings,
    :duration,
    :job,
    attachment: [:url, :filename, :byte_size]
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket =
      socket
      |> assign_import(id)
      |> subscribe_for_updates()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  defp subscribe_for_updates(socket) do
    with true <- connected?(socket),
         %Socket{assigns: %{import: import}} <- socket,
         %Import{id: id} <- import,
         topic <- "import:updated:#{id}" do
      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for import updates: #{other}")
        socket
    end
  end

  defp assign_import(socket, id) do
    {:ok, import} = Import.get_by_id(id, load: @load)
    assign(socket, :import, import)
  end

  defp update_import(socket) do
    %Socket{assigns: %{import: %Import{id: id}}} = socket
    assign_import(socket, id)
  end

  defp apply_action(socket, :show, _params) do
    assign(socket, :page_title, ~t"Show Import"m)
  end

  defp apply_action(socket, action, _params) do
    assign(socket, :page_title, "Action #{action}")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:imports} environment={@environment} sidebar_nav={@sidebar_nav}>
      <div class="bg-base-100/75 sticky top-16 z-20 backdrop-blur">
        <.import_header import={@import} action={@live_action} />
      </div>

      <.render_action import={@import} action={@live_action} />

      <:portal>
        <.modal
          :if={@live_action == :mappings}
          id="mappings-modal"
          on_cancel={JS.patch(~p"/imports/#{@import}")}
        >
          <.import_mapping_form import={@import} patch={~p"/imports/#{@import}"} />
        </.modal>
      </:portal>
    </.page>
    """
  end

  attr :import, Import, required: true
  attr :action, :atom, default: nil

  def import_header(assigns) do
    ~H"""
    <.header>
      <div class="flex items-center justify-between">
        <h1><%= ~t"Import Records"m %></h1>
      </div>

      <:subtitle>
        <ol class="flex items-center space-x-4 text-sm">
          <li class="flex items-center space-x-2">
            <.import_attachment import={@import} />
          </li>
        </ol>
      </:subtitle>

      <:actions>
        <div class="flex items-center gap-4">
          <div :if={@import.missing_mappings != []} class="text-error">
            <.icon name="hero-exclamation-triangle-solid" /> Mapping is invalid
          </div>

          <.button
            phx-click="import:run"
            disabled={@import.state == :running || @import.missing_mappings != []}
          >
            Run Import
          </.button>
        </div>
      </:actions>
    </.header>
    """
  end

  attr :import, :map, required: true
  attr :action, :atom, required: true

  def render_action(%{import: import, action: action} = assigns)
      when action in [:show, :mappings] do
    {mapped_columns, unmapped_columns} = Enum.split_with(import.columns, & &1.mapped?)

    assigns =
      assigns
      |> assign(:mapped_columns, mapped_columns)
      |> assign(:unmapped_columns, unmapped_columns)

    ~H"""
    <div class="space-y-12">
      <div>
        <.header>
          Import
          <:actions>
            <div class="flex items-center gap-4">
              <span>State:</span>
              <.import_state_badge import={@import} />
            </div>
          </:actions>
        </.header>

        <.list>
          <:item title="File"><.import_attachment import={@import} /></:item>
          <:item title="Created at"><%= format_datetime(@import.inserted_at) %></:item>
          <:item title="Rows"><%= format_number(@import.rows_count) %></:item>

          <:item title="Validation">
            <div class="flex flex-col">
              <.progress value={@import.validation_progress || 0} max={1} class="w-56" />
              <div>
                <%= format_number(@import.rows_validated_count) %> / <%= format_number(
                  @import.rows_count
                ) %> rows
              </div>
              <div :if={@import.rows_invalid_count not in [0, nil]} class="text-error">
                invalid rows: <%= format_number(@import.rows_invalid_count) %>
              </div>
            </div>
          </:item>

          <:item title="Imported">
            <div class="flex flex-col">
              <.progress value={@import.import_progress || 0} max={1} class="w-56" />
              <div>
                <%= format_number(@import.rows_imported_count) %> / <%= format_number(
                  @import.rows_count
                ) %> rows
              </div>
            </div>
          </:item>

          <:item title="Started at">
            <div :if={@import.finished_at == nil}>
              <%= format_datetime(@import.started_at) %>
            </div>
            <div :if={@import.finished_at != nil}>
              <%= format_date_interval(@import.started_at, @import.finished_at) %>
            </div>
            <%= @import.duration %>
          </:item>

          <:item title="Job">
            <div :if={@import.job}>
              <%= @import.job.id %> <%= @import.job.state %>
            </div>
          </:item>
        </.list>
      </div>

      <div>
        <.header>
          Mapping
          <:subtitle>Map columns to record attributes</:subtitle>

          <:actions>
            <.link
              class="btn btn-primary btn-sm rounded-full"
              patch={~p"/imports/#{@import}/mappings"}
            >
              <%= ~t"Edit Mapping"m %>
            </.link>
          </:actions>
        </.header>

        <div class="m-8">
          <.import_mapping_validation import={@import} />
        </div>

        <.list>
          <:item title="Unmapped Columns">
            <span
              :for={col <- @unmapped_columns}
              class="bg-base-200 mr-1 mb-1 inline-flex rounded px-2 py-1 text-xs"
            >
              <%= col.name %>
            </span>
          </:item>

          <:item title="Mapped Columns">
            <.table id="mappings" rows={@mapped_columns}>
              <:col :let={column} label={~t"Column"m}>
                <%= column.name %>
              </:col>
              <:col :let={column} label={~t"Mapped to"m}>
                <%= column.mapped_to %>
              </:col>
            </.table>
          </:item>
        </.list>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({_topic, _event, _notification}, socket) do
    socket = update_import(socket)
    {:noreply, socket}
  end

  def handle_info({MappingForm, {:saved, _import}}, socket) do
    socket = update_import(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("import:run", _params, socket) do
    %Socket{assigns: %{import: import}} = socket

    socket =
      case Import.enqueue_import(import) do
        {:ok, import} ->
          assign(socket, :import, import)

        {:error, error} ->
          Logger.error(error)
          put_flash(socket, :error, ~t"Import could not be started"m)
      end

    {:noreply, socket}
  end
end
