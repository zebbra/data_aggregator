defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias Phoenix.LiveView.Socket

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

  defp apply_action(socket, :show, _params) do
    assign(socket, :page_title, ~t"Show Collection"m)
  end

  defp apply_action(socket, :import, _params) do
    assign(socket, :page_title, ~t"Import Records"m)
  end

  @spec queue(Record.t()) :: :ok
  defp queue(record) do
    Record.enqueue_encoder!(record)

    :ok
  end

  @impl true
  def handle_event("encode_collection", _params, socket) do
    live_view = self()

    Task.start(fn ->
      collection = socket.assigns.collection

      collection.records
      |> Task.async_stream(&queue(&1))
      |> Stream.run()

      # we update the encoding state after the encoding has been queued
      send(live_view, {:encoding_state, :encoding})
    end)

    {:noreply, assign(socket, :encoding_state, :encoding)}
  end

  def handle_info({:encoding_state, state}, socket) do
    {:noreply, assign(socket, encoding_state: state)}
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.CollectionLive.ImportFormComponent, {:imported, import}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:import, import)
     |> push_navigate(to: ~p"/imports/#{import}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:collections} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky flex">
        <.button
          class="inline-block align-middle"
          to={~p"/collections"}
          size="xxl"
          link_type="live_redirect"
          color="ghost"
          label={~t"Collections"m}
          responsive
        />
        <.icon class="inline-block align-middle" name="hero-chevron-right" />
        <span class="inline-block align-middle"><%= @collection.name %></span>
        <:actions>
          <.button
            id="import-modal__button"
            to={~p"/collections/#{@collection}/import"}
            link_type="live_patch"
            icon="hero-plus"
            label={~t"Import"m}
            responsive
          />

          <.button
            color="primary"
            id="encode_start__button"
            phx-click="encode_collection"
            link_type="live_patch"
            icon="hero-puzzle-piece"
            label={~t"Encode"m}
            responsive
          />
        </:actions>
      </.header>

      <div class="grid justify-items-center">
        <dl class="mt-5 grid grid-cols-2 gap-5 md:grid-cols-3 xl:grid-cols-6">
          <.stat_card label={~t"Name"m} stat={@collection.name} />
          <.stat_card label={~t"Owner"m} stat={@collection.owner} />
          <.stat_card label={~t"Records in Collection"m} stat={@collection.records_count} />

          <.stat_card
            label={~t"Digitization Progress"m}
            stat={
              @collection.digitizing_progress
              |> Decimal.from_float()
              |> Decimal.round(1)
            }
            stat_suffix="%"
          />
          <.stat_card
            label={~t"Encoded"m}
            stat={"#{@collection.records_count_encoded} / #{@collection.records_count}"}
          />
          <div class="overflow-hidden rounded-md border border-indigo-400 bg-white px-4 py-5 shadow dark:border-gray-600 dark:bg-gray-900 sm:p-6">
            <dt class="truncate text-sm font-medium text-gray-500">
              Encoding State
            </dt>
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-700 dark:text-gray-200">
              <.encoding_state state={@encoding_state} />
            </dd>
          </div>
        </dl>
      </div>

      <:portal>
        <.modal
          :if={@live_action == :import}
          id="import-modal"
          on_cancel={JS.patch(~p"/collections/#{@collection}")}
        >
          <.live_component
            module={DataAggregatorWeb.CollectionLive.ImportFormComponent}
            id={"import_form-#{@collection.id}"}
            icon="hero-plus-circle-mini"
            title={@page_title}
            action={:new}
            collection={@collection}
            patch={~p"/collections/#{@collection}"}
          />
        </.modal>
      </:portal>
    </.page>
    """
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
