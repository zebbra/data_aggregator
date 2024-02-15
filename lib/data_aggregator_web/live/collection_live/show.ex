defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias Phoenix.LiveView.Socket

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  require Logger

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> subscribe_for_updates()

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = get_collection(id)

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:encoding_state, get_encoding_state(collection))
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <.header>
        <:navbar>
          <.secondary_navigation>
            <.secondary_navigation_item
              href={~p"/collections/#{@collection.id}"}
              label={~t"Records"m}
              active
            />
            <.secondary_navigation_item
              href={~p"/collections/#{@collection.id}"}
              label={~t"Imports"m}
            />
            <.secondary_navigation_item
              href={~p"/collections/#{@collection.id}"}
              label={~t"Encodings"m}
            />
            <.secondary_navigation_item
              href={~p"/collections/#{@collection.id}"}
              label={~t"Collection Information"m}
            />
          </.secondary_navigation>
        </:navbar>
        <:breadcrumbs>
          <.breadcrumbs
            class="sm:hidden text-sm"
            items={[
              %{label: ~t"Collections"m, link: ~p"/collections"},
              %{label: ~t"Records"m, link: ~p"/collections/#{@collection.id}"}
            ]}
          />
        </:breadcrumbs>
        <.breadcrumbs
          class="max-sm:hidden text-lg/6"
          items={[
            %{label: ~t"Collections"m, link: ~p"/collections"},
            %{label: @collection.name, link: ~p"/collections/#{@collection.id}"}
          ]}
        />
        <div class="flex items-center gap-x-3 sm:hidden">
          <.state_indicator state={@encoding_state} />
          <%= @collection.name %>
        </div>
        <:subtitle :if={@collection.description}><%= @collection.description %></:subtitle>
        <:actions>
          <.link patch={~p"/collections/new"} class="btn btn-neutral max-sm:btn-sm">
            <.icon name="hero-plus-mini" class="max-sm:hidden" />
            <span class="max-sm:hidden"><%= ~t"Import dataset"m %></span>
            <span class="sm:hidden"><%= ~t"Add"m %></span>
          </.link>
        </:actions>
      </.header>

      <div class="px-6 max-md:hidden lg:px-8">
        <div class="grid grid-cols-2 gap-2 lg:grid-cols-4">
          <.scope_stat title={~t"All records"m} value={1.0} desc={@collection.records_count} active />
          <.scope_stat
            title={~t"Not encoded"m}
            value={
              if @collection.records_count_not_encoded == 0,
                do: 1,
                else: @collection.records_count_not_encoded / @collection.records_count
            }
            desc={@collection.records_count_not_encoded}
          />
          <.scope_stat title={~t"Unpublished"m} value={0.0} desc={0} />
          <.scope_stat
            title={~t"Records with issues"m}
            value={
              if @collection.records_count_failed == 0,
                do: 0,
                else: @collection.records_count_failed / @collection.records_count
            }
            desc={@collection.records_count_failed}
          />
        </div>
      </div>

      <%!-- <div class="bg-base-100 top-[104px] sticky z-10 flex flex-wrap justify-between p-6 lg:px-8">
        <div class="join flex flex-wrap items-center">
          <input
            type="text"
            placeholder={~t"Search...."m}
            class="input input-bordered border-black-white/10 join-item "
          />
          <button class="btn btn-outline border-black-white/10 join-item">
            <.icon name="hero-adjustments-vertical" />
            <span class="hidden font-normal lg:inline"><%= ~t"Filter"m %></span>
          </button>
          <button class="btn btn-outline border-black-white/10 join-item">
            <.icon name="hero-view-columns" />
            <span class="hidden font-normal lg:inline"><%= ~t"Columns"m %></span>
          </button>
          <button class="btn btn-outline border-black-white/10 join-item">
            <.icon name="hero-square-3-stack-3d" />
            <span class="hidden font-normal lg:inline"><%= ~t"Layers"m %></span>
          </button>
        </div>
        <div id="table actions" class="join flex lg:justify-end">
          <button class="btn btn-outline border-black-white/10 join-item rounded-full">
            <.icon name="hero-puzzle-piece" />
            <span class="font-normal"><%= ~t"Encode"m %></span>
          </button>
          <button class="btn btn-outline border-black-white/10 join-item rounded-full">
            <.icon name="hero-globe-alt" />
            <span class="font-normal"><%= ~t"Publish"m %></span>
          </button>
          <button class="btn btn-outline border-black-white/10 join-item rounded-full">
            <.icon name="hero-arrow-down-tray" />
            <span class="font-normal"><%= ~t"Export"m %></span>
          </button>
        </div>
      </div> --%>
    </.page>
    """
  end

  defp apply_action(socket, :show, _params) do
    assign(socket, :page_title, ~t"Show Collection"m)
  end

  defp subscribe_for_updates(socket) do
    with true <- connected?(socket),
         %Socket{assigns: %{collection: collection}} <- socket,
         %Collection{id: id} <- collection,
         topic <- "collection:updated:#{id}" do
      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for collection updates: #{other}")
        socket
    end
  end

  defp get_encoding_state(collection) do
    cond do
      collection.records_count_encoded == collection.records_count ->
        :encoded

      collection.records_count_encoding > 0 or collection.records_count_encoding_queued > 0 ->
        :encoding

      collection.records_count_failed > 0 ->
        :failed

      collection.records_count > collection.records_count_encoded ->
        :incomplete

      true ->
        :unknown
    end
  end

  defp get_collection(id) do
    Collection.get_by_id!(id,
      load: [
        :records,
        :records_count,
        :digitizing_progress,
        :records_count_not_encoded,
        :records_count_imported,
        :records_count_encoding_queued,
        :records_count_encoding,
        :records_count_encoded,
        :records_count_failed
      ]
    )
  end
end
