defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components, only: [scope_stat: 1]

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]
  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, subscribe_for_updates: 2]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> subscribe_for_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <.collection_header collection={@collection} current={:records} />
      <div class="px-6 lg:px-8">
        <div class="grid grid-cols-2 gap-2 md:grid-cols-4">
          <.scope_stat
            href="#"
            title={~t"All records"m}
            value={1.0}
            desc={@collection.records_count}
            active
          />
          <.scope_stat
            href="#"
            title={~t"Not encoded"m}
            value={
              if @collection.records_count_not_encoded == 0,
                do: 1,
                else: @collection.records_count_not_encoded / @collection.records_count
            }
            desc={@collection.records_count_not_encoded}
          />
          <.scope_stat href="#" title={~t"Unpublished"m} value={0.0} desc={0} />
          <.scope_stat
            href="#"
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

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Records"m)
  end
end
