defmodule DataAggregatorWeb.CollectionLive.Import.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Import.Components, only: [import_state_badge: 1]

  alias DataAggregator.PubSub
  alias DataAggregator.Records
  alias DataAggregator.Records.Import
  alias DataAggregatorWeb.Components.DataTable

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers

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
      assign(socket, :collection, get_collection(id))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> assign(count: Records.count!(collection_scope(params)))
      |> assign_imports(params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <.collection_header collection={@collection} current={:imports} />
      <div :if={@count > 0} class="no-scrollbar overflow-x-auto py-4">
        <.table
          id="imports_table"
          rows={@streams.results}
          row_click={
            fn {_id, import} ->
              if import.state == :pending,
                do: JS.navigate(~p"/collections/#{@collection}/imports/#{import}/edit")
            end
          }
        >
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
                "link link-primary link-hover tooltip tooltip-primary rounded-md",
                can_run?(import) == false && "btn-disabled opacity-60",
                import.state != :pending && "hidden"
              ]}
              data-tip={~t"Run"m}
            >
              <.icon name="hero-play-circle-mini" class="size-6" />
            </button>

            <button
              type="button"
              phx-click={JS.push("import:delete", value: %{id: import.id})}
              class={[
                "link link-error link-hover tooltip tooltip-error rounded-md",
                import.state != :pending && "hidden"
              ]}
              data-tip={~t"Delete"m}
              data-confirm={~t"Are you sure?"m}
            >
              <.icon name="hero-x-circle-mini" class="size-6" />
            </button>
          </:action>
        </.table>
      </div>

      <.empty_state
        :if={@count == 0}
        title={~t"No imports"m}
        description={~t"Get started by importing a new dataset."m}
        label={~t"Import"m}
        icon="hero-arrow-down-tray"
        href={~p"/collections/#{@collection}/imports/new"}
      />

      <:portal>
        <.modal
          id="import_modal"
          class="no-scrollbar"
          show={@live_action in [:new, :edit, :summary]}
          size="2xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(~p"/collections/#{@collection}/imports")}
        >
          <.live_component
            :if={@live_action in [:new, :edit, :summary]}
            module={DataAggregatorWeb.CollectionLive.Import.FormComponent}
            id={@import.id || :new}
            action={@live_action}
            import={@import}
            collection={@collection}
            show_validation={Phoenix.Flash.get(@flash, :mapping_error)}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_info({topic, _event, notification}, socket)
      when topic in ["import:created", "import:updated"] do
    %Ash.Notifier.Notification{data: import} = notification
    import = Records.load!(import, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, import)}
  end

  @impl true
  def handle_info({"import:destroyed", _event, notification}, socket) do
    %Ash.Notifier.Notification{data: import} = notification
    {:noreply, stream_delete(socket, :results, import)}
  end

  @impl true
  def handle_event("import:run", %{"id" => id}, socket) do
    id |> Import.get_by_id!() |> Import.enqueue_import!()
    {:noreply, socket}
  end

  @impl true
  def handle_event("import:delete", %{"id" => id}, socket) do
    import = Import.get_by_id!(id)
    :ok = Import.destroy(import)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Import deleted successfully"m)
     |> stream_delete(:results, import)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Collection Imports"m)
    |> assign(:import, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Import"m)
    |> assign(:import, %Import{})
  end

  defp apply_action(socket, :edit, %{"import_id" => id}) do
    import = Import.get_by_id!(id, load: [:collection, :missing_mappings, :mappings])

    socket
    |> assign(:page_title, ~t"Edit Import"m)
    |> assign(:import, import)
  end

  defp apply_action(socket, :summary, %{"id" => collection_id, "import_id" => id}) do
    import = Import.get_by_id!(id, load: [:missing_mappings])

    if Enum.empty?(import.missing_mappings) do
      socket
      |> assign(:page_title, ~t"Import Summary"m)
      |> assign(:import, import)
    else
      socket
      |> put_flash(:mapping_error, true)
      |> push_patch(to: ~p"/collections/#{collection_id}/imports/#{import}/edit")
    end
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
end
