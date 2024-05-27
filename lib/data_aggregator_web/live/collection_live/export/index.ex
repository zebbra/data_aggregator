defmodule DataAggregatorWeb.CollectionLive.Export.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Export.Components, only: [export_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Export.Helpers
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records
  alias DataAggregator.Records.Export

  @load [
    :duration,
    :attachment_filename,
    :attachment_byte_size,
    attachment: [:filename, :url, :byte_size]
  ]

  @load_export @load ++
                 [
                   :job,
                   :export_progress
                 ]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> assign(selected_export: nil)
      |> subscribe_for_export_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    case list_exports(params) do
      {:ok, {records, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, records, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/exports")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_export != nil}>
      <.collection_header collection={@collection} current={:exports} />
      <.secondary_navigation class="sticky top-[calc(4rem-1px)]">
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/records"}
          label={~t"Records"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/imports"}
          label={~t"Imports"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/exports"}
          label={~t"Exports"m}
          active
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
        path={~p"/collections/#{@collection}/exports"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, export} ->
            JS.push("export:select", value: %{id: export.id})
          end
        }
      >
        <:col :let={{_id, export}} field={:state} label={~t"State"m}>
          <.export_state_badge export={export} />
        </:col>
        <:col :let={{_id, export}} label={~t"File"m}>
          <.file_info attachment={export.attachment} rows={export.rows_count} />
        </:col>
        <:col :let={{_id, export}} label={~t"Size"m}>
          <.attachment_download_badge :if={export.attachment != nil} attachment={export.attachment} />
        </:col>
        <:col :let={{_id, export}} field={:started_at} label={~t"Started at"m}>
          <%= format_datetime(export.started_at, format: :short) %>
          <div :if={export.duration} class="text-base-content/60 text-xs">
            <%= export.duration %>
          </div>
        </:col>
        <:col :let={{_id, export}} field={:rows_count} label={~t"Records"m} class="text-right">
          <%= format_number(export.rows_count, format: :short) %>
        </:col>

        <:action
          :let={{_id, export}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div :if={can_run?(export)} class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.link
              phx-click="export:run"
              phx-value-id={export.id}
              class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
              data-tip={~t"Run"m}
            >
              <.icon name="hero-play-circle-mini" class="size-5 text-base-content/75" />
            </.link>
          </div>
          <.link
            phx-click={JS.push("export:delete", value: %{id: export.id})}
            class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
          >
            <.icon name="hero-trash-mini" class="size-5 text-base-content/75" />
          </.link>
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/collections/#{@collection}/exports"} />

      <:secondary>
        <.slideover
          title={if @selected_export != nil, do: @selected_export.name, else: ~t"Export"m}
          subtitle={~t"Export status details."m}
          open={@selected_export != nil}
          on_cancel={JS.push("export:select", value: %{id: nil})}
          size="xl"
        >
          <.section_heading
            text={~t"Export"m}
            class="border-b border-black-white/10 px-6 sm:px-8 pb-6"
            align_items={if can_run?(@selected_export), do: "center", else: "baseline"}
            size="md"
          >
            <:subtitle>
              <div :if={@selected_export.state == :pending} class="mt-1 flex items-center gap-x-2">
                <span class="text-sm"><%= ~t"State:"m %></span>
                <.export_state_badge export={@selected_export} />
              </div>
            </:subtitle>
            <:actions>
              <button
                :if={can_run?(@selected_export)}
                type="button"
                phx-value-id={@selected_export.id}
                phx-click="export:run"
                class="btn btn-primary max-sm:btn-sm"
              >
                <.icon name="hero-play-circle-mini" class="size-6" />
                <%= ~t"Run"m %>
              </button>
              <div
                :if={can_run?(@selected_export) == false && @selected_export.state != :pending}
                class="flex items-center gap-x-2"
              >
                <span class="text-sm"><%= ~t"State:"m %></span>
                <.export_state_badge export={@selected_export} />
              </div>
            </:actions>
          </.section_heading>

          <.list>
            <:item title={~t"File"m}>
              <.file_info
                attachment={@selected_export.attachment}
                rows={@selected_export.rows_count}
                badge
              />
            </:item>
            <:item title={~t"Created at"m}>
              <%= format_datetime(@selected_export.inserted_at) %>
            </:item>
            <:item title={~t"Rows"m}><%= format_number(@selected_export.rows_count) %></:item>

            <:item title={~t"Exported"m}>
              <div class="flex flex-col">
                <.progress
                  value={@selected_export.export_progress || 0}
                  max={1}
                  class="w-full progress progress-primary"
                />
                <div>
                  <%= format_number(@selected_export.exported_count) %> / <%= format_number(
                    @selected_export.rows_count
                  ) %> <%= ~t"rows"m %>
                </div>
              </div>
            </:item>

            <:item title={~t"Started at"m}>
              <div :if={@selected_export.finished_at == nil}>
                <%= format_datetime(@selected_export.started_at) %>
              </div>
              <div :if={@selected_export.finished_at != nil}>
                <%= format_date_interval(@selected_export.started_at, @selected_export.finished_at) %>
              </div>
              <%= @selected_export.duration %>
            </:item>

            <:item title={~t"Job"m}>
              <div :if={@selected_export.job}>
                <%= @selected_export.job.id %> <%= @selected_export.job.state %>
              </div>
            </:item>
          </.list>

          <:footer :if={@selected_export && @selected_export.state == :pending}>
            <button
              type="button"
              phx-click={JS.push("export:delete", value: %{id: @selected_export.id})}
              class="btn btn-error max-sm:btn-sm"
              data-confirm={~t"Are you sure?"m}
            >
              <.icon name="hero-x-circle-mini" class="size-6" />
              <%= ~t"Delete"m %>
            </button>
          </:footer>
        </.slideover>
      </:secondary>
    </.page>
    """
  end

  @impl true
  def handle_event("export:run", %{"id" => id}, socket) do
    id |> Export.get_by_id!() |> Export.enqueue!()
    {:noreply, socket}
  end

  @impl true
  def handle_event("export:delete", %{"id" => id}, socket) do
    export = Export.get_by_id!(id)
    :ok = Export.destroy(export)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Export deleted successfully"m)
     |> assign(:selected_export, nil)
     |> stream_delete(:results, export)}
  end

  @impl true
  def handle_event("export:select", %{"id" => nil}, socket) do
    socket =
      assign(socket, :selected_export, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("export:select", %{"id" => id}, socket) do
    socket =
      assign(socket, :selected_export, Export.get_by_id!(id, load: @load_export))

    {:noreply, socket}
  end

  @impl true
  def handle_info({topic, _event, notification}, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "export:#{id}:created" -> handle_export_created(notification, socket)
      topic == "export:#{id}:updated" -> handle_export_updated(notification, socket)
      topic == "export:#{id}:destroyed" -> handle_export_destroyed(notification, socket)
      true -> {:noreply, socket}
    end
  end

  defp handle_export_created(notification, socket) do
    %Ash.Notifier.Notification{data: export} = notification
    export = Records.load!(export, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, export, at: 0)}
  end

  defp handle_export_updated(notification, socket) do
    %Ash.Notifier.Notification{data: export} = notification

    if socket.assigns.selected_export != nil && export.id == socket.assigns.selected_export.id do
      export = Export.get_by_id!(export.id, load: @load_export)

      {:noreply, socket |> assign(:selected_export, export) |> stream_insert(:results, export, at: 0)}
    else
      handle_export_created(notification, socket)
    end
  end

  defp handle_export_destroyed(notification, socket) do
    %Ash.Notifier.Notification{data: export} = notification
    {:noreply, stream_delete(socket, :results, export)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Collection Exports"m)
    |> assign(:export, nil)
  end

  defp list_exports(params, opts \\ [load: @load, action: :by_collection]) do
    Pagify.validate_and_run(Export, params, opts, params["id"])
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No exports"m}
      description={~t"Get started by exporting records."m}
      label={~t"Export"m}
      icon="hero-arrow-down-tray"
      href={~p"/collections/#{@collection}/records"}
    />
    """
  end
end
