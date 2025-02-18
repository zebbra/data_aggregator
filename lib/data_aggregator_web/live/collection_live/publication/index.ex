defmodule DataAggregatorWeb.CollectionLive.Publication.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Publication.Subscriptions

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_light: 2, cancel_action: 2, busy_action: 1]

  import DataAggregatorWeb.CollectionLive.Publication.Components,
    only: [publication_state_badge: 1, publication_channel_badge: 1]

  import DataAggregatorWeb.CollectionLive.Publication.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  @load load()
  @load_publication load_all()

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    collection = get_collection_light(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(selected_publication: nil)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> subscribe_for_publication_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case list_publications(params, actor, tenant) do
      {:ok, {publications, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, publications, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, %AshPagify.Meta{errors: []}} ->
        raise ~t"Something went wrong"m

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/publications")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user} open={@selected_publication != nil}>
      <.collection_header
        collection={@collection}
        current={:publications}
        current_user={@current_user}
        busy={@busy}
        busy_action={@busy_action}
      />
      <.secondary_navigation class="top-[calc(4rem-1px)] sticky">
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/records"} label={~t"Records"m} />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/imports"} label={~t"Imports"m} />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/exports"} label={~t"Exports"m} />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/publications"}
          label={~t"Publications and Validations"m}
          active
        />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/image_uploads"}
          label={~t"Image Upload"m}
        />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/published_records"}
          label={~t"Published Records"m}
        />
      </.secondary_navigation>

      <.table
        opts={[
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/datasets/#{@collection}/publications"}
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
          {format_datetime(publication.started_at, format: :short)}
          <div :if={publication.duration} class="text-base-content/60 text-xs">
            {publication.duration}
          </div>
        </:col>
        <:col :let={{_id, publication}} field={:started_by} label={~t"Started by"m}>
          {maybe_set_user(publication.started_by)}
        </:col>
        <:col :let={{_id, publication}} field={:rows_count} label={~t"Records"m} class="text-right">
          {format_number(publication.rows_count, format: :short)}
        </:col>

        <:action
          :let={{_id, publication}}
          :if={Collection.can_set_importing?(@current_user, @collection)}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div
            :if={can_run?(publication)}
            class="border-black-white/10 mr-4 inline-flex border-r pr-4"
          >
            <.table_action_button
              phx-click="publication:run"
              phx-value-id={publication.id}
              data-tip={~t"Run"m}
              icon="hero-play-circle-mini"
            />
          </div>
          <.table_action_button
            phx-click={JS.push("publication:delete", value: %{id: publication.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_publication_alert"
            disabled={can_delete?(publication) == false}
            icon="hero-trash-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/datasets/#{@collection}/publications"} />

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
            class="border-black-white/10 border-b px-6 pb-6 sm:px-8"
            align_items="center"
            size="md"
          >
            <:subtitle>
              <div
                :if={@selected_publication.state == :pending}
                class="mt-1 flex items-center gap-x-2"
              >
                <span class="text-sm">{~t"State:"m}</span>
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
                <.icon name="hero-play-circle-mini" class="size-6" /> {~t"Run"m}
              </button>
              <div :if={can_run?(@selected_publication) == false} class="flex items-center gap-x-2">
                <span class="text-sm">{~t"State:"m}</span>
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
              {format_datetime(@selected_publication.inserted_at)}
            </:item>
            <:item title={~t"Rows"m}>{format_number(@selected_publication.rows_count)}</:item>

            <:item title={~t"Done"m}>
              <div class="flex flex-col">
                <.progress
                  value={@selected_publication.publication_progress || 0}
                  max={1}
                  class="progress progress-primary w-full"
                />
                <div>
                  {format_number(@selected_publication.published_count)} / {format_number(
                    @selected_publication.rows_count
                  )} {~t"rows"m}
                </div>
              </div>
            </:item>

            <:item title={~t"Started by"m}>
              {maybe_set_user(@selected_publication.started_by)}
            </:item>
            <:item title={~t"Started at"m}>
              <div :if={@selected_publication.finished_at == nil}>
                {format_datetime(@selected_publication.started_at)}
              </div>
              <div :if={@selected_publication.finished_at != nil}>
                {format_date_interval(
                  @selected_publication.started_at,
                  @selected_publication.finished_at
                )}
              </div>
              {@selected_publication.duration}
            </:item>
            <:item title={~t"License"m}>
              {@selected_publication.license}
            </:item>
          </.list>

          <:footer :if={
            not is_nil(@selected_publication) &&
              Publication.can_destroy?(@current_user, @selected_publication)
          }>
            <button
              type="button"
              phx-click={JS.push("publication:delete", value: %{id: @selected_publication.id})}
              class="btn btn-error max-sm:btn-sm"
              data-confirm={~t"Are you sure?"m}
              data-confirm_id="confirm_publication_alert"
              disbled={can_delete?(@selected_publication) == false}
            >
              <.icon name="hero-x-circle-mini" class="size-6" /> {~t"Delete"m}
            </button>
          </:footer>
        </.slideover>
      </:secondary>

      <:portal>
        <.alert
          id="confirm_publication_alert"
          size="sm"
          title={~t"Are you sure?"m}
          label={~t"Yes, delete publication"m}
        />
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("collection:cancel", %{"id" => id}, socket) do
    cancel_action(id, socket)
  end

  @impl true
  def handle_event("publication:run", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case id
         |> Publication.get_by_id!(actor: actor, tenant: tenant)
         |> Publication.enqueue(%{started_by_id: actor.id}, actor: actor) do
      {:ok, publication} ->
        {:noreply, put_flash(socket, :info, publication_success_message(publication))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"A publication for this dataset is already in process"m)}
    end
  end

  @impl true
  def handle_event("publication:delete", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    publication = Publication.get_by_id!(id, actor: actor, tenant: tenant)
    :ok = Publication.destroy(publication, actor: actor, tenant: tenant)

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
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    socket =
      assign(
        socket,
        :selected_publication,
        Publication.get_by_id!(id, load: @load_publication, actor: actor, tenant: tenant)
      )

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Dataset Publications"m)
    |> assign(:publication, nil)
  end

  defp list_publications(params, actor, tenant, opts \\ [load: @load]) do
    opts = Keyword.put_new(opts, :actor, actor)
    opts = Keyword.put_new(opts, :tenant, tenant)
    AshPagify.validate_and_run(Publication, params, opts)
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No publications"m}
      description={~t"Get started by publishing records."m}
      icon="hero-globe-alt"
    />
    """
  end

  defp publication_success_message(%{channel: :validation}) do
    ~t"Validation started in background"m
  end

  defp publication_success_message(_), do: ~t"Publication started in background"m
end
