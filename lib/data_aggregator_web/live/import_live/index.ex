defmodule DataAggregatorWeb.ImportLive.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.ImportLive.Components

  alias DataAggregator.PubSub
  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  @load [
    # :import_progress,
    # :validation_progress,
    :duration,
    :collection_name,
    :records_count,
    :attachment_filename,
    :attachment_byte_size,
    # :rows_valid_ratio,
    attachment: [:filename, :url, :byte_size]
  ]

  @topics ["import:created", "import:updated", "import:destroyed"]

  @impl true
  def mount(_params, _session, socket) do
    # Replace with? https://hexdocs.pm/ash_phoenix/AshPhoenix.LiveView.html#keep_live/4
    # socket = socket |> assign_live(:imports, &list_imports/1, subscribe: @topics)
    if connected?(socket), do: PubSub.subscribe(@topics)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_imports()
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp assign_imports(socket) do
    stream(socket, :results, list_imports())
  end

  defp list_imports do
    Import.read!(load: @load)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Show Import"m)
    |> assign(:import, Import.get_by_id!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Listing Imports"m)
    |> assign(:import, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:imports} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        <%= ~t"Listing Imports"m %>
      </.header>

      <.table
        id="imports"
        rows={@streams.results}
        row_click={
          fn {_id, import} ->
            JS.navigate(~p"/imports/#{import}")
          end
        }
      >
        <:col :let={{_id, import}} label={~t"State"m} field="state">
          <.import_state_badge import={import} />
        </:col>

        <:col :let={{_id, import}} label={~t"File"m} field="attachment_filename">
          <div class="font-mono"><%= import.attachment.filename %></div>
          <div class="text-base-content/50 text-xs"><%= format_number(import.rows_count) %> rows</div>
        </:col>

        <:col :let={{_id, import}} label={~t"Size"m} field="attachment_byte_size">
          <.attachment_download_badge attachment={import.attachment} />
        </:col>

        <:col :let={{_id, import}} label={~t"Collection"m} field="collection_name">
          <%= import.collection_name %>
        </:col>

        <:col :let={{_id, import}} label={~t"Started at"m} field="started_at">
          <%= format_datetime(import.started_at, format: :short) %>
          <%= import.duration %>
        </:col>

        <:col :let={{_id, import}} label={~t"Records"m} field="records_count">
          <%= format_number(import.records_count, format: :short) %>
        </:col>

        <:action :let={{_id, import}}>
          <div class="sr-only">
            <.link patch={~p"/imports/#{import}"}><%= ~t"Show"m %></.link>
          </div>
        </:action>

        <:action :let={{_id, import}}>
          <.link phx-click="import:run" phx-value-id={import.id}>
            <%= ~t"Run"m %>
          </.link>
        </:action>

        <:action :let={{id, import}}>
          <.link
            phx-click={JS.push("import:delete", value: %{id: import.id}) |> hide("##{id}")}
            data-confirm={~t"Are you sure?"m}
          >
            <%= ~t"Delete"m %>
          </.link>
        </:action>
      </.table>
    </.page>
    """
  end

  @impl true
  def handle_info({DataAggregatorWeb.ImportLive.FormComponent, {:saved, import}}, socket) do
    {:noreply, stream_insert(socket, :results, import)}
  end

  def handle_info({topic, _event, notification}, socket) when topic in ["import:created", "import:updated"] do
    %Ash.Notifier.Notification{data: import} = notification
    import = Records.load!(import, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, import)}
  end

  def handle_info({"import:destroyed", _event, notification}, socket) do
    %Ash.Notifier.Notification{data: import} = notification
    {:noreply, stream_delete(socket, :results, import)}
  end

  @impl true
  def handle_event("import:delete", %{"id" => id}, socket) do
    id |> Import.get_by_id!() |> Import.destroy!()
    {:noreply, socket}
  end

  def handle_event("import:run", %{"id" => id}, socket) do
    id |> Import.get_by_id!() |> Import.enqueue_import!()
    {:noreply, socket}
  end
end
