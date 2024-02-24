defmodule DataAggregatorWeb.CollectionLive.Import.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Import.Components, only: [import_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records
  alias DataAggregator.Records.Import
  alias DataAggregatorWeb.Components.DataTable

  @load [
    :duration,
    :collection_name,
    :records_count,
    :missing_mappings,
    :attachment_filename,
    :attachment_byte_size,
    attachment: [:filename, :url, :byte_size]
  ]

  @load_import @load ++
                 [
                   :job,
                   :import_progress,
                   :rows_validated_count,
                   :rows_invalid_count,
                   :validation_progress,
                   :mappings
                 ]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> subscribe_for_import_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(selected_import: nil)
      |> assign(:collection, get_collection(id))
      |> assign(count: Records.count!(collection_scope(params)))
      |> assign_imports(params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_import != nil}>
      <.collection_header collection={@collection} current={:imports} />
      <div :if={@count > 0} class="no-scrollbar overflow-x-auto py-4">
        <.table
          id="imports_table"
          rows={@streams.results}
          row_click={
            fn {_id, import} ->
              JS.push("import:select", value: %{id: import.id})
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
            <button
              :if={can_run?(import)}
              type="button"
              phx-click="import:run"
              phx-value-id={import.id}
              class="link link-primary link-hover tooltip tooltip-primary rounded-md"
              data-tip={~t"Run"m}
            >
              <.icon name="hero-play-circle-mini" class="size-6" />
            </button>

            <div :if={import.missing_mappings != []} class="text-base-content">
              <%= ~t"Mapping is invalid"m %>
            </div>

            <button
              :if={import.state == :pending}
              type="button"
              phx-click={JS.navigate(~p"/collections/#{@collection}/imports/#{import}/edit")}
              class="link link-base-100 link-hover tooltip rounded-md"
              data-tip={~t"Edit"m}
            >
              <.icon name="hero-pencil-square-mini" class="size-6" />
            </button>

            <button
              type="button"
              phx-click={JS.push("import:delete", value: %{id: import.id})}
              class="link link-error link-hover tooltip tooltip-error rounded-md"
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
        icon="hero-arrow-up-tray"
        href={~p"/collections/#{@collection}/imports/new"}
      />

      <:secondary>
        <.slideover
          title={~t"Show import"m}
          subtitle={~t"Import status and mapping details."m}
          open={@selected_import != nil}
          on_cancel={JS.push("import:select", value: %{id: nil})}
          size="xl"
        >
          <div>
            <div class="border-black-white/10 border-b px-6 pb-8 sm:px-8">
              <div class="flex w-full items-center">
                <div class="min-w-0 flex-1">
                  <h4 class="text-base-content font-bold">
                    <%= ~t"Import"m %>
                  </h4>
                </div>
                <div class="shrink-0">
                  <button
                    :if={can_run?(@selected_import)}
                    type="button"
                    phx-value-id={@selected_import.id}
                    phx-click="import:run"
                    class="btn btn-primary max-sm:btn-sm"
                  >
                    <.icon name="hero-play-circle-mini" class="size-6" />
                    <%= ~t"Run import"m %>
                  </button>
                  <div
                    :if={can_run?(@selected_import) == false && @selected_import.state == :pending}
                    class="text-error flex h-8 items-center gap-x-2"
                  >
                    <.icon name="hero-exclamation-triangle-mini" class="size-6 mt-0.5" />
                    <span class="text-sm"><%= ~t"Mapping is invalid"m %></span>
                  </div>
                  <div
                    :if={can_run?(@selected_import) == false && @selected_import.state != :pending}
                    class="flex items-center gap-x-2"
                  >
                    <span class="text-sm"><%= ~t"State:"m %></span>
                    <.import_state_badge import={@selected_import} />
                  </div>
                </div>
              </div>
              <div :if={@selected_import.state == :pending} class="flex items-center gap-x-2">
                <span class="text-sm"><%= ~t"State:"m %></span>
                <.import_state_badge import={@selected_import} />
              </div>
            </div>
            <.list>
              <:item title={~t"File"m}>
                <div class="font-mono"><%= @selected_import.attachment.filename %></div>
                <div class="text-base-content/50 mt-1 flex items-center gap-x-2 text-xs">
                  <.attachment_download_badge attachment={@selected_import.attachment} />
                  <%= format_number(@selected_import.rows_count) %> rows
                </div>
              </:item>
              <:item title={~t"Created at"m}>
                <%= format_datetime(@selected_import.inserted_at) %>
              </:item>
              <:item title={~t"Rows"m}><%= format_number(@selected_import.rows_count) %></:item>

              <:item title={~t"Validation"m}>
                <div class="flex flex-col">
                  <.progress
                    value={@selected_import.validation_progress || 0}
                    max={1}
                    class="w-full progress progress-primary"
                  />
                  <div>
                    <%= format_number(@selected_import.rows_validated_count) %> / <%= format_number(
                      @selected_import.rows_count
                    ) %> <%= ~t"rows"m %>
                  </div>
                  <div :if={@selected_import.rows_invalid_count not in [0, nil]} class="text-error">
                    <%= ~t"invalid rows:"m %> <%= format_number(@selected_import.rows_invalid_count) %>
                  </div>
                </div>
              </:item>

              <:item title={~t"Imported"m}>
                <div class="flex flex-col">
                  <.progress
                    value={@selected_import.import_progress || 0}
                    max={1}
                    class="w-full progress progress-primary"
                  />
                  <div>
                    <%= format_number(@selected_import.rows_imported_count) %> / <%= format_number(
                      @selected_import.rows_count
                    ) %> <%= ~t"rows"m %>
                  </div>
                </div>
              </:item>

              <:item title={~t"Started at"m}>
                <div :if={@selected_import.finished_at == nil}>
                  <%= format_datetime(@selected_import.started_at) %>
                </div>
                <div :if={@selected_import.finished_at != nil}>
                  <%= format_date_interval(@selected_import.started_at, @selected_import.finished_at) %>
                </div>
                <%= @selected_import.duration %>
              </:item>

              <:item title={~t"Job"m}>
                <div :if={@selected_import.job}>
                  <%= @selected_import.job.id %> <%= @selected_import.job.state %>
                </div>
              </:item>
            </.list>
          </div>

          <div>
            <div class="border-black-white/10 flex w-full items-center border-b px-6 pb-8 sm:px-8">
              <div class="min-w-0 flex-1">
                <h4 class="text-base-content font-bold">
                  <%= ~t"Mapping"m %>
                </h4>
              </div>
              <div :if={@selected_import.state == :pending} class="flex shrink-0 items-center gap-x-2">
                <.link
                  type="button"
                  patch={~p"/collections/#{@collection}/imports/#{@selected_import}/edit"}
                  class="btn btn-primary max-sm:btn-sm"
                >
                  <.icon name="hero-pencil-square-mini" class="size-6" />
                  <%= ~t"Edit mapping"m %>
                </.link>
              </div>
            </div>

            <div class="no-scrollbar overflow-x-auto">
              <.table id="import_mapping_table" rows={@selected_import.mappings}>
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
                    @selected_import.columns
                    |> Enum.filter(&(&1.mapped? == false))
                    |> Enum.map(& &1.name)
                }
                class="bg-base-200 mr-1 mb-1 inline-flex rounded px-2 py-1 text-xs"
              >
                <%= col %>
              </span>
            </div>
          </div>

          <:footer :if={@selected_import && @selected_import.state == :pending}>
            <button
              type="button"
              phx-click={JS.push("import:delete", value: %{id: @selected_import.id})}
              class="btn btn-error max-sm:btn-sm"
              data-confirm={~t"Are you sure?"m}
            >
              <.icon name="hero-x-circle-mini" class="size-6" />
              <%= ~t"Delete"m %>
            </button>
          </:footer>
        </.slideover>
      </:secondary>

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
     |> assign(:selected_import, nil)
     |> stream_delete(:results, import)}
  end

  @impl true
  def handle_event("import:select", %{"id" => nil}, socket) do
    socket =
      assign(socket, :selected_import, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("import:select", %{"id" => id}, socket) do
    socket =
      assign(socket, :selected_import, Import.get_by_id!(id, load: @load_import))

    {:noreply, socket}
  end

  @impl true
  def handle_info({topic, _event, notification}, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "import:#{id}:created" -> handle_import_created(notification, socket)
      topic == "import:#{id}:updated" -> handle_import_updated(notification, socket)
      topic == "import:#{id}:destroyed" -> handle_import_destroyed(notification, socket)
      true -> {:noreply, socket}
    end
  end

  defp handle_import_created(notification, socket) do
    %Ash.Notifier.Notification{data: import} = notification
    import = Records.load!(import, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, import, at: 0)}
  end

  defp handle_import_updated(notification, socket) do
    %Ash.Notifier.Notification{data: import} = notification

    if socket.assigns.selected_import != nil && import.id == socket.assigns.selected_import.id do
      import = Import.get_by_id!(import.id, load: @load_import)

      {:noreply, socket |> assign(:selected_import, import) |> stream_insert(:results, import, at: 0)}
    else
      handle_import_created(notification, socket)
    end
  end

  defp handle_import_destroyed(notification, socket) do
    %Ash.Notifier.Notification{data: import} = notification
    {:noreply, stream_delete(socket, :results, import)}
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
    import = Import.get_by_id!(id, load: @load_import)

    if Enum.empty?(import.missing_mappings) do
      socket
      |> assign(:page_title, ~t"Import Summary"m)
      |> assign(:import, import)
    else
      socket
      |> put_flash(:mapping_error, true)
      |> push_navigate(to: ~p"/collections/#{collection_id}/imports/#{import}/edit")
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

  defp collection_scope(params) do
    Ash.Query.filter_input(Import, %{"collection" => %{"id" => params["id"]}})
  end
end
