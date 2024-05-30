defmodule DataAggregatorWeb.CollectionLive.Import.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Import.Components, only: [import_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.Import

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
                   :mappings,
                   :collection
                 ]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> assign(selected_import: nil)
      |> subscribe_for_import_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    case list_imports(params) do
      {:ok, {records, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, records, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/imports")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_import != nil}>
      <.collection_header collection={@collection} current={:imports} meta={@meta} />
      <.secondary_navigation class="sticky top-[calc(4rem-1px)]">
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/records"}
          label={~t"Records"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/imports"}
          label={~t"Imports"m}
          active
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/exports"}
          label={~t"Exports"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/publications"}
          label={~t"Publications"m}
        />
      </.secondary_navigation>

      <.table
        opts={[
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/collections/#{@collection}/imports"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, import} ->
            JS.push("import:select", value: %{id: import.id})
          end
        }
      >
        <:col :let={{_id, import}} field={:state} label={~t"State"m}>
          <.import_state_badge import={import} />
        </:col>
        <:col :let={{_id, import}} label={~t"File"m}>
          <.file_info attachment={import.attachment} rows={import.rows_count} />
        </:col>
        <:col :let={{_id, import}} label={~t"Size"m}>
          <.attachment_download_badge attachment={import.attachment} />
        </:col>
        <:col :let={{_id, import}} field={:started_at} label={~t"Started at"m}>
          <%= format_datetime(import.started_at, format: :short) %>
          <div :if={import.duration} class="text-base-content/60 text-xs">
            <%= import.duration %>
          </div>
        </:col>
        <:col :let={{_id, import}} field={:records_count} label={~t"Records"m} class="text-right">
          <%= format_number(import.records_count, format: :short) %>
        </:col>

        <:action
          :let={{_id, import}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div
            :if={import.missing_mappings != []}
            class="link tooltip link-hover btn btn-sm btn-circle btn-ghost inline-flex"
            data-tip={~t"Mapping is invalid"m}
          >
            <.icon name="hero-exclamation-circle-mini" class="size-5 text-base-content/75" />
          </div>

          <.link
            :if={can_run?(import)}
            type="button"
            phx-click="import:run"
            phx-value-id={import.id}
            class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
            data-tip={~t"Run"m}
          >
            <.icon name="hero-play-circle-mini" class="size-5 text-base-content/75" />
          </.link>

          <div class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.link
              :if={import.state == :pending}
              patch={build_path(~p"/collections/#{@collection}/imports/#{import}/edit", @meta)}
              class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
              data-tip={~t"Edit"m}
            >
              <.icon name="hero-pencil-square-mini" class="size-5 text-base-content/75" />
            </.link>
          </div>

          <.link
            type="button"
            phx-click={JS.push("import:delete", value: %{id: import.id})}
            class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
          >
            <.icon name="hero-trash-mini" class="size-5 text-base-content/75" />
          </.link>
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/collections/#{@collection}/imports"} />

      <:secondary>
        <.slideover
          title={~t"Show import"m}
          subtitle={~t"Import status and mapping details."m}
          open={@selected_import != nil}
          on_cancel={JS.push("import:select", value: %{id: nil})}
          size="xl"
        >
          <.section_heading
            text={~t"Import"m}
            class="border-b border-black-white/10 px-6 lg:px-8 pb-6"
            align_items={
              if @selected_import.state == :imported,
                do: "baseline",
                else: "center"
            }
            size="md"
          >
            <:subtitle>
              <div :if={@selected_import.state == :pending} class="mt-1 flex items-center gap-x-2">
                <span class="text-sm"><%= ~t"State:"m %></span>
                <.import_state_badge import={@selected_import} />
              </div>
            </:subtitle>
            <:actions>
              <button
                :if={can_run?(@selected_import)}
                type="button"
                phx-value-id={@selected_import.id}
                phx-click="import:run"
                class="btn btn-primary max-sm:btn-sm"
              >
                <.icon name="hero-play-circle-mini" class="size-6" />
                <%= ~t"Run"m %>
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
            </:actions>
          </.section_heading>

          <.list>
            <:item title={~t"File"m}>
              <.file_info
                attachment={@selected_import.attachment}
                rows={@selected_import.rows_count}
                badge
              />
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

          <.table id="import_mapping_table" items={@selected_import.mappings}>
            <:caption>
              <.section_heading
                text={~t"Mapping"m}
                class="border-b border-black-white/10 px-6 pb-6 lg:px-8 text-left"
                align_items="center"
                size="md"
              >
                <:actions :if={@selected_import.state == :pending}>
                  <.link
                    type="button"
                    patch={
                      build_path(
                        ~p"/collections/#{@collection}/imports/#{@selected_import}/edit",
                        @meta
                      )
                    }
                    class="btn btn-primary max-sm:btn-sm"
                  >
                    <.icon name="hero-pencil-square-mini" class="size-6" />
                    <%= ~t"Edit"m %>
                  </.link>
                </:actions>
              </.section_heading>
            </:caption>
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

          <div class="px-6 py-4 lg:px-8">
            <.section_heading text={~t"Unmapped columns"m} class="pb-4" size="md" />
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
          on_cancel={JS.patch(build_path(~p"/collections/#{@collection}/imports", @meta))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :edit, :summary]}
            module={DataAggregatorWeb.CollectionLive.Import.FormComponent}
            id={@import.id || :new}
            action={@live_action}
            import={@import}
            collection={@collection}
            show_validation={Phoenix.Flash.get(@flash, :mapping_error)}
            meta={@meta}
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
    import = Import.get_by_id!(import.id, load: @load_import)
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
    import = Import.get_by_id!(id, load: @load_import)

    socket
    |> assign(:page_title, ~t"Edit Import"m)
    |> assign(:selected_import, nil)
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

  defp list_imports(params, opts \\ [load: @load, action: :by_collection]) do
    Pagify.validate_and_run(Import, params, opts, params["id"])
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No imports"m}
      description={~t"Get started by importing a new dataset."m}
      label={~t"Import"m}
      icon="hero-arrow-up-tray"
      href={~p"/collections/#{@collection}/imports/new"}
    />
    """
  end
end
