defmodule DataAggregatorWeb.CollectionLive.Import.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Import.Components, only: [import_state_badge: 1]

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Import
  alias DataAggregatorWeb.Components.DataTable

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]
  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, subscribe_for_updates: 2]

  @load [
    :duration,
    :collection_name,
    :records_count,
    :missing_mappings,
    :attachment_filename,
    :attachment_byte_size,
    attachment: [:filename, :url, :byte_size]
  ]

  @topics ["import:created", "import:updated", "import:destroyed"]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    connected = connected?(socket)

    # Replace with? https://hexdocs.pm/ash_phoenix/AshPhoenix.LiveView.html#keep_live/4
    # socket = socket |> assign_live(:imports, &list_imports/1, subscribe: @topics)
    if connected, do: PubSub.subscribe(@topics)

    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> subscribe_for_updates(connected)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> assign_imports(params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <.collection_header collection={@collection} current={:imports} />
      <div class="no-scrollbar overflow-x-auto py-4">
        <.table id="imports_table" rows={@streams.results}>
          <:col :let={{_id, import}} label={~t"State"m}>
            <.import_state_badge import={import} />
          </:col>
          <:col :let={{_id, import}} label={~t"File"m}>
            <div class="font-mono"><%= import.attachment.filename %></div>
            <div class="text-base-content/50 text-xs">
              <%= format_number(import.rows_count) %> rows
            </div>
          </:col>
          <:col :let={{_id, import}} label={~t"Size"m}>
            <.attachment_download_badge attachment={import.attachment} />
          </:col>
          <:col :let={{_id, import}} label={~t"Started at"m}>
            <%= format_datetime(import.started_at, format: :short) %>
            <div :if={import.duration} class="text-base-content/50 text-xs">
              <%= import.duration %>
            </div>
          </:col>
          <:col :let={{_id, import}} label={~t"Records"m} class="text-right">
            <%= format_number(import.records_count, format: :short) %>
          </:col>
          <:action :let={{_id, import}} class="flex items-center justify-end gap-x-2">
            <div :if={import.missing_mappings != []} class="text-error">
              <%= ~t"Mapping is invalid"m %>
            </div>
            <button
              type="button"
              phx-click="import:run"
              phx-value-id={import.id}
              class={[
                "link link-primary link-hover tooltip font-semibold",
                can_run?(import) == false && "btn-disabled opacity-60",
                import.state != :pending && "hidden"
              ]}
              data-tip={~t"Run"m}
            >
              <.icon name="hero-play-circle-mini" class="size-6" />
            </button>
          </:action>
        </.table>
      </div>
    </.page>
    """
  end

  @impl true
  def handle_info({topic, _event, notification}, socket)
      when topic in ["import:created", "import:updated"] do
    %Ash.Notifier.Notification{data: import} = notification
    import = Import.get_by_id!(import.id, load: @load)

    {:noreply, stream_insert(socket, :results, import)}
  end

  @impl true
  def handle_info({"import:destroyed", _event, notification}, socket) do
    %Ash.Notifier.Notification{data: import} = notification
    {:noreply, stream_delete(socket, :results, import)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Imports"m)
  end

  defp assign_imports(socket, params) do
    stream(socket, :results, list_imports(params))
  end

  defp list_imports(params) do
    opts = DataTable.read_opts(collection_scope(params), params)
    opts = Keyword.put(opts, :load, @load)

    {:ok, result} = Import.read(opts)

    case result do
      %Ash.Page.Offset{results: imports} -> imports
      imports -> imports
    end
  end

  defp collection_scope(params) do
    Import |> Ash.Query.filter_input(%{"collection" => %{"id" => params["id"]}})
  end

  defp can_run?(import) do
    cond do
      length(import.missing_mappings) > 0 -> false
      import.state in [:pending] -> true
      true -> false
    end
  end
end
