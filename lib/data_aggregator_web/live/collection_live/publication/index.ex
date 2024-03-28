defmodule DataAggregatorWeb.CollectionLive.Publication.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Publication.Components, only: [publication_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]
  import DataAggregatorWeb.CollectionLive.Publication.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records
  alias DataAggregator.Records.Publication
  alias DataAggregatorWeb.Components.DataTable

  @load [
    :duration,
    :attachment_filename,
    :attachment_byte_size,
    attachment: [:filename, :url, :byte_size]
  ]

  @load_publication @load ++
                      [
                        :job,
                        :publication_progress
                      ]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      assign(socket, :collection, get_collection(id))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(selected_publication: nil)
      |> assign(:collection, get_collection(id))
      |> assign(count: Records.count!(collection_scope(params)))
      |> assign_publications(params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_publication != nil}>
      <.collection_header collection={@collection} current={:publications} />
      <.secondary_navigation class="sticky top-[calc(4rem-1px)]" gradient>
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
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/publications"}
          label={~t"Publications"m}
          active
        />
      </.secondary_navigation>
      <div :if={@count > 0} class="no-scrollbar overflow-x-auto py-4">
        <.table
          id="publications_table"
          rows={@streams.results}
          row_click={
            fn {_id, publication} ->
              JS.push("publication:select", value: %{id: publication.id})
            end
          }
        >
          <:col :let={{_id, publication}} label={~t"State"m}>
            <.publication_state_badge publication={publication} />
          </:col>
          <:col :let={{_id, publication}} label={~t"Channel"m} class="text-center">
            <.publication_channel_badge channel={publication.channel} />
          </:col>
          <:col :let={{_id, publication}} label={~t"File"m}>
            <div class="font-mono">
              <%= if publication.attachment != nil, do: publication.attachment.filename, else: "-" %>
            </div>
            <div class="text-base-content/60 text-xs">
              <%= format_number(publication.rows_count) %> rows
            </div>
          </:col>
          <:col :let={{_id, publication}} label={~t"Size"m}>
            <.attachment_download_badge
              :if={publication.attachment != nil}
              attachment={publication.attachment}
            />
          </:col>
          <:col :let={{_id, publication}} label={~t"Started at"m}>
            <%= format_datetime(publication.started_at, format: :short) %>
            <div :if={publication.duration} class="text-base-content/60 text-xs">
              <%= publication.duration %>
            </div>
          </:col>
          <:col :let={{_id, publication}} label={~t"Records"m} class="text-right">
            <%= format_number(publication.rows_count, format: :short) %>
          </:col>

          <:action :let={{_id, publication}} class="flex items-center justify-end gap-x-2">
            <button
              :if={can_run?(publication)}
              type="button"
              phx-click="publication:run"
              phx-value-id={publication.id}
              class="link link-primary link-hover tooltip tooltip-primary rounded-md"
              data-tip={~t"Run"m}
            >
              <.icon name="hero-play-circle-mini" class="size-6" />
            </button>

            <button
              type="button"
              phx-click={JS.push("publication:delete", value: %{id: publication.id})}
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
        title={~t"No publications"m}
        description={~t"Get started by publishing records."m}
        label={~t"Publication"m}
        icon="hero-arrow-down-tray"
        href={~p"/collections/#{@collection}/records"}
      />

      <:secondary>
        <.slideover
          title={
            if @selected_publication != nil, do: @selected_publication.name, else: ~t"Publication"m
          }
          subtitle=""
          open={@selected_publication != nil}
          on_cancel={JS.push("publication:select", value: %{id: nil})}
          size="xl"
        >
          <div>
            <.section_heading
              text={~t"Publication"m}
              class="border-b border-black-white/10 px-6 sm:px-8 pb-8"
              size="md"
            >
              <:subtitle>
                <div :if={@selected_publication.state == :pending} class="flex items-center gap-x-2">
                  <.publication_state_badge publication={@selected_publication} />
                </div>
              </:subtitle>
              <:actions>
                <button
                  :if={can_run?(@selected_publication)}
                  type="button"
                  phx-value-id={@selected_publication.id}
                  phx-click="publication:run"
                  class="btn btn-primary max-sm:btn-sm"
                >
                  <.icon name="hero-play-circle-mini" class="size-6" />
                  <%= ~t"Run"m %>
                </button>
                <div
                  :if={
                    can_run?(@selected_publication) == false &&
                      @selected_publication.state != :pending
                  }
                  class="flex items-center gap-x-2"
                >
                  <.publication_state_badge publication={@selected_publication} />
                </div>
              </:actions>
            </.section_heading>

            <.list>
              <:item title={~t"File"m}>
                <div class="font-mono">
                  <%= if @selected_publication.attachment != nil,
                    do: @selected_publication.attachment.filename,
                    else: "-" %>
                </div>
                <div class="text-base-content/60 mt-1 flex items-center gap-x-2 text-xs">
                  <.attachment_download_badge
                    :if={@selected_publication.attachment != nil}
                    attachment={@selected_publication.attachment}
                  />
                  <%= format_number(@selected_publication.rows_count) %> rows
                </div>
              </:item>
              <:item title={~t"Created at"m}>
                <%= format_datetime(@selected_publication.inserted_at) %>
              </:item>
              <:item title={~t"Rows"m}><%= format_number(@selected_publication.rows_count) %></:item>

              <:item title={~t"Published"m}>
                <div class="flex flex-col">
                  <.progress
                    value={@selected_publication.publication_progress || 0}
                    max={1}
                    class="w-full progress progress-primary"
                  />
                  <div>
                    <%= format_number(@selected_publication.published_count) %> / <%= format_number(
                      @selected_publication.rows_count
                    ) %> <%= ~t"rows"m %>
                  </div>
                </div>
              </:item>

              <:item title={~t"Started at"m}>
                <div :if={@selected_publication.finished_at == nil}>
                  <%= format_datetime(@selected_publication.started_at) %>
                </div>
                <div :if={@selected_publication.finished_at != nil}>
                  <%= format_date_interval(
                    @selected_publication.started_at,
                    @selected_publication.finished_at
                  ) %>
                </div>
                <%= @selected_publication.duration %>
              </:item>

              <:item title={~t"Job"m}>
                <div :if={@selected_publication.job}>
                  <%= @selected_publication.job.id %> <%= @selected_publication.job.state %>
                </div>
              </:item>
            </.list>
          </div>

          <:footer :if={@selected_publication && @selected_publication.state == :pending}>
            <button
              type="button"
              phx-click={JS.push("publication:delete", value: %{id: @selected_publication.id})}
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
  def handle_event("publication:run", %{"id" => id}, socket) do
    id |> Publication.get_by_id!() |> Publication.enqueue!()
    {:noreply, socket}
  end

  @impl true
  def handle_event("publication:delete", %{"id" => id}, socket) do
    publication = Publication.get_by_id!(id)
    :ok = Publication.destroy(publication)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Publication deleted successfully"m)
     |> assign(:selected_publication, nil)
     |> stream_delete(:results, publication)}
  end

  @impl true
  def handle_event("publication:select", %{"id" => nil}, socket) do
    socket =
      assign(socket, :selected_publication, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("publication:select", %{"id" => id}, socket) do
    socket =
      assign(socket, :selected_publication, Publication.get_by_id!(id, load: @load_publication))

    {:noreply, socket}
  end

  @impl true
  def handle_info({topic, _event, notification}, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "publication:#{id}:created" -> handle_publication_created(notification, socket)
      topic == "publication:#{id}:updated" -> handle_publication_updated(notification, socket)
      topic == "publication:#{id}:destroyed" -> handle_publication_destroyed(notification, socket)
      true -> {:noreply, socket}
    end
  end

  defp handle_publication_created(notification, socket) do
    %Ash.Notifier.Notification{data: publication} = notification
    publication = Records.load!(publication, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, publication, at: 0)}
  end

  defp handle_publication_updated(notification, socket) do
    %Ash.Notifier.Notification{data: publication} = notification

    if socket.assigns.selected_publication != nil &&
         publication.id == socket.assigns.selected_publication.id do
      publication = Publication.get_by_id!(publication.id, load: @load_publication)

      {:noreply,
       socket
       |> assign(:selected_publication, publication)
       |> stream_insert(:results, publication, at: 0)}
    else
      handle_publication_created(notification, socket)
    end
  end

  defp handle_publication_destroyed(notification, socket) do
    %Ash.Notifier.Notification{data: publication} = notification
    {:noreply, stream_delete(socket, :results, publication)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Collection Publications"m)
    |> assign(:publication, nil)
  end

  defp assign_publications(socket, params) do
    stream(socket, :results, list_publications(params))
  end

  defp list_publications(params) do
    opts = DataTable.read_opts(collection_scope(params), params)
    opts = Keyword.put(opts, :load, @load)

    {:ok, result} = Publication.read(opts)

    case result do
      %Ash.Page.Offset{results: publications} -> publications
      publications -> publications
    end
  end

  defp collection_scope(params) do
    Ash.Query.filter_input(Publication, %{"collection" => %{"id" => params["id"]}})
  end
end
