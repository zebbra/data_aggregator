defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection =
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

    socket =
      socket
      |> assign(:collection, collection)
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

    # TO-DO: check this then add encoding batch (rotating icon) to collection overview page
    Stream.chunk_every(collection.records, 10)
    |> Stream.map(&queue_chunk(&1))
    |> Stream.run()

    {:noreply, socket}
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
      <.header class="top-16 sticky">
        <%= @collection.name %>

        <:actions>
          <.button
            to={~p"/collections"}
            link_type="live_redirect"
            color="secondary"
            icon="hero-arrow-left-mini"
            label={~t"Back to Collections"m}
            responsive
          />
          <.button
            id="import-modal__button"
            to={~p"/collections/#{@collection}/import"}
            link_type="live_patch"
            icon="hero-plus-circle-mini"
            label={~t"Import Records"m}
            responsive
          />
          <.button
            id="encode-modal__button"
            phx-click="encode_collection"
            link_type="live_patch"
            icon="hero-arrow-path-rounded-square"
            label={~t"Encode Records"m}
            responsive
          />
        </:actions>
      </.header>

      <div class="grid justify-items-center">
        <dl class="mt-5 grid grid-cols-2 gap-5 md:grid-cols-3 xl:grid-cols-6">
          <.stat_card label={~t"Name"m} stat={@collection.name} />
          <.stat_card label={~t"Owner"m} stat={@collection.owner} />
          <.stat_card label={~t"Type"m} stat="OTHERS" />
          <.stat_card label={~t"Records in Collection"m} stat={@collection.records_count} />
          <.stat_card
            label={~t"Encoded"m}
            stat={"#{@collection.records_count_encoded} / #{@collection.records_count}"}
          />
          <.stat_card
            label={~t"Digitization Progress"m}
            stat={
              @collection.digitizing_progress
              |> Decimal.from_float()
              |> Decimal.round(1)
            }
            stat_suffix="%"
          />
          <div class="overflow-hidden rounded-lg border border-indigo-400 bg-white px-4 py-5 shadow dark:border-gray-600 dark:bg-gray-900 sm:p-6">
            <dt class="truncate text-sm font-medium text-gray-500">
              Encoding State
            </dt>
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-700 dark:text-gray-200">
              <.encoding_state collection={@collection} />
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

  def encoding_state(assigns) do
    collection =
      Records.load!(
        assigns.collection,
        [
          :records_count,
          :records_count_not_encoded,
          :records_count_imported,
          :records_count_encoding_queued,
          :records_count_encoding,
          :records_count_encoded,
          :records_count_failed
        ],
        lazy?: true
      )

    case collection_state(collection) do
      :encoded ->
        ~H"""
        <div class="badge badge-success">
          encoded
        </div>
        """

      :failed ->
        ~H"""
        <div class="badge badge-error">
          failed
        </div>
        """

      :encoding ->
        ~H"""
        <div class="badge badge-info">
          encoding...
        </div>
        """

      :not_encoded ->
        ~H"""
        <div class="badge badge-secondary">
          not encoded
        </div>
        """
    end
  end

  defp collection_state(collection) do
    cond do
      collection.records_count_encoded == collection.records_count ->
        :encoded

      collection.records_count_failed > 0 ->
        :failed

      collection.records_count_encoding > 0 or collection.records_count_encoding_queued > 0 ->
        :encoding

      true ->
        :not_encoded
    end
  end
end
