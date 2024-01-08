defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @impl true
  def mount(_params, _session, socket) do
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

  defp apply_action(socket, :show, _params) do
    assign(socket, :page_title, ~t"Show Collection"m)
  end

  defp apply_action(socket, :import, _params) do
    assign(socket, :page_title, ~t"Import Records"m)
  end

  @impl true
  def handle_event("encode_collection", _params, socket) do
    collection = socket.assigns.collection

    Stream.chunk_every(collection.records, 10)
    |> Stream.map(&queue_chunk(&1))
    |> Stream.run()

    {:noreply, assign(socket, :encoding_state, get_encoding_state(collection))}
  end

  @spec queue_chunk([Record.t()]) :: :ok
  defp queue_chunk(records) do
    Enum.each(records, &Record.enqueue_encoder(&1))
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
            :if={@encoding_state != :encoding}
            color="primary"
            id="encode_start__button"
            phx-click="encode_collection"
            link_type="live_patch"
            icon="hero-puzzle-piece"
            label={~t"Encode"m}
            responsive
          />
          <.button
            :if={@encoding_state == :encoding}
            disabled
            id="encoding__button"
            link_type="live_patch"
            icon="hero-cog-6-tooth-solid animate-spin"
            label={~t"Encoding"m}
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

      collection.records_count_failed > 0 ->
        :failed

      collection.records_count_encoding > 0 or collection.records_count_encoding_queued > 0 ->
        :encoding

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
