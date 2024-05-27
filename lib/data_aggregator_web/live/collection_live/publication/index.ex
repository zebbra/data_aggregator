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
      socket
      |> assign(:collection, get_collection(id))
      |> assign(selected_publication: nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    case list_publications(params) do
      {:ok, {publications, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, publications, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/publications")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_publication != nil}>
      <.collection_header collection={@collection} current={:publications} />
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
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/publications"}
          label={~t"Publications"m}
          active
        />
      </.secondary_navigation>

      <.table
        opts={[
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/collections/#{@collection}/publications"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, publication} ->
            JS.push("publication:select", value: %{id: publication.id})
          end
        }
      >
        <:col :let={{_id, publication}} field={:state} label={~t"State"m}>
          <.publication_state_badge publication={publication} />
        </:col>
        <:col :let={{_id, publication}} field={:channel} label={~t"Channel"m} class="text-center">
          <.publication_channel_badge channel={publication.channel} />
        </:col>
        <:col :let={{_id, publication}} label={~t"File"m}>
          <.file_info attachment={publication.attachment} rows={publication.rows_count} />
        </:col>
        <:col :let={{_id, publication}} label={~t"Size"m}>
          <.attachment_download_badge
            :if={publication.attachment != nil}
            attachment={publication.attachment}
          />
        </:col>
        <:col :let={{_id, publication}} field={:started_at} label={~t"Started at"m}>
          <%= format_datetime(publication.started_at, format: :short) %>
          <div :if={publication.duration} class="text-base-content/60 text-xs">
            <%= publication.duration %>
          </div>
        </:col>
        <:col :let={{_id, publication}} field={:rows_count} label={~t"Records"m} class="text-right">
          <%= format_number(publication.rows_count, format: :short) %>
        </:col>

        <:action
          :let={{_id, publication}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div
            :if={can_run?(publication)}
            class="border-black-white/10 mr-4 inline-flex border-r pr-4"
          >
            <.link
              phx-click="publication:run"
              phx-value-id={publication.id}
              class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
              data-tip={~t"Run"m}
            >
              <.icon name="hero-play-circle-mini" class="size-5 text-base-content/75" />
            </.link>
          </div>
          <.link
            phx-click={JS.push("publication:delete", value: %{id: publication.id})}
            class="link tooltip inline-flex link-hover btn btn-sm btn-circle btn-ghost"
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
          >
            <.icon name="hero-trash-mini" class="size-5 text-base-content/75" />
          </.link>
        </:action>
      </.table>

      <:secondary>
        <.slideover
          title={
            if @selected_publication != nil, do: @selected_publication.name, else: ~t"Publication"m
          }
          subtitle={~t"Publication status details."m}
          open={@selected_publication != nil}
          on_cancel={JS.push("publication:select", value: %{id: nil})}
          size="xl"
        >
          <.section_heading
            text={~t"Publication"m}
            class="border-b border-black-white/10 px-6 sm:px-8 pb-6"
            align_items="center"
            size="md"
          >
            <:subtitle>
              <div
                :if={@selected_publication.state == :pending}
                class="mt-1 flex items-center gap-x-2"
              >
                <span class="text-sm"><%= ~t"State:"m %></span>
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
                <span class="text-sm"><%= ~t"State:"m %></span>
                <.publication_state_badge publication={@selected_publication} />
              </div>
            </:actions>
          </.section_heading>

          <.list>
            <:item title={~t"Channel"m}>
              <.publication_channel_badge channel={@selected_publication.channel} />
            </:item>
            <:item title={~t"File"m}>
              <.file_info
                attachment={@selected_publication.attachment}
                rows={@selected_publication.rows_count}
                badge
              />
            </:item>
            <:item title={~t"Created at"m}>
              <%= format_datetime(@selected_publication.inserted_at) %>
            </:item>
            <:item title={~t"Rows"m}><%= format_number(@selected_publication.rows_count) %></:item>

            <:item title={~t"Done"m}>
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

  defp list_publications(params, opts \\ [load: @load, action: :by_collection]) do
    Pagify.validate_and_run(Publication, params, opts, params["id"])
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No publications"m}
      description={~t"Get started by publishing records."m}
      label={~t"Publication"m}
      icon="hero-arrow-down-tray"
      href={~p"/collections/#{@collection}/records"}
    />
    """
  end
end
