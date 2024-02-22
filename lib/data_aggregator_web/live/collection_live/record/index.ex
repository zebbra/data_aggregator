defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components, only: [scope_stat: 1]
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record
  alias DataAggregatorWeb.Components.DataTable

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.RecordLive.Helpers,
    only: [attrs_by_category_in_layers: 1, encoded_attribute: 2]

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [subscribe_for_record_updates: 2]
  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, subscribe_for_collection_updates: 2]

  @load [:collection, :encoded_record]

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:collection, get_collection(id))
      |> subscribe_for_record_updates(connected?(socket))
      |> subscribe_for_collection_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = get_collection(id)

    socket =
      socket
      |> assign(:collection, collection)
      |> assign_records(params)
      |> assign(selected_record: nil)
      |> assign(:busy, collection.encoding_state in [:queued, :encoding])
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_record != nil}>
      <.collection_header collection={@collection} current={:records} />
      <div :if={length(@collection.records) > 0} class="space-y-6 p-6 lg:px-8">
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
        <div class="flex min-w-0 flex-1 justify-end gap-x-2">
          <.link
            phx-click="collection:export"
            class="btn btn-primary text-primary-content max-sm:btn-sm"
            disabled={@busy}
          >
            <.icon name="hero-arrow-down-tray" class="max-sm:size-4" />
            <%= ~t"Export"m %>
          </.link>
          <.link
            :if={@busy == false}
            phx-click="collection:encode"
            class="btn btn-primary text-primary-content max-sm:btn-sm"
          >
            <.icon name="hero-puzzle-piece" class="max-sm:size-4" />
            <%= ~t"Encode"m %>
          </.link>
          <.link
            :if={@busy}
            patch={~p"/collections/#{@collection}/records"}
            class="btn btn-error text-error-content max-sm:btn-sm"
          >
            <.icon name="hero-arrow-path" class="max-sm:size-4" />
            <%= ~t"Refresh"m %>
          </.link>
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
        <div id="table_actions" class="join flex lg:justify-end">
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

      <div :if={length(@collection.records) > 0} class="no-scrollbar overflow-x-auto py-4">
        <.table
          id="records_table"
          rows={@streams.results}
          row_click={
            fn {_id, record} ->
              JS.push("record:select", value: %{id: record.id})
            end
          }
        >
          <:col :let={{_id, record}} label={~t"MaterialEntityID"m} class="font-semibold">
            <%= record.mte_material_entity_id %>
          </:col>
          <:col :let={{_id, record}} label={~t"Scientific Name"m}>
            <%= encoded_attribute(record, :tax_scientific_name) %>
          </:col>
          <:col :let={{_id, record}} label={~t"Genus"m}>
            <%= encoded_attribute(record, :tax_genus) %>
          </:col>
          <:col :let={{_id, record}} label={~t"Family"m}>
            <%= encoded_attribute(record, :tax_family) %>
          </:col>
          <:col :let={{_id, record}} label={~t"Order"m}>
            <%= encoded_attribute(record, :tax_order) %>
          </:col>
          <:col :let={{_id, record}} label={~t"Class"m}>
            <%= encoded_attribute(record, :tax_class) %>
          </:col>
          <:col :let={{_id, record}} label={~t"Phylum"m}>
            <%= encoded_attribute(record, :tax_phylum) %>
          </:col>
          <:col :let={{_id, record}} label={~t"Encoding"m} class="text-center">
            <.encoding_state_badge state={record.state} />
          </:col>
          <:col :let={{_id, record}} label={~t"Updated At"m} class="text-end">
            <%= format_datetime(record.updated_at, format: :medium) %>
          </:col>
        </.table>
      </div>

      <.empty_state
        :if={length(@collection.records) == 0}
        title={~t"No records"m}
        description={~t"Get started by importing a new dataset"m}
        label={~t"Import"m}
        icon="hero-bug-ant"
        href={~p"/collections/#{@collection}/imports/new"}
      />

      <:secondary>
        <.slideover
          title={@selected_record != nil && encoded_attribute(@selected_record, :tax_scientific_name)}
          subtitle={~t"Characteristics according to the darwin core standard"m}
          open={@selected_record != nil}
          on_cancel={JS.push("record:select", value: %{id: nil})}
          size="xl"
        >
          <%= for category <- @attrs_in_categories do %>
            <section>
              <.heading
                title={category.label}
                subtitle={category.description}
                size="sm"
                class="px-6 sm:px-8"
              />
              <div class="no-scrollbar overflow-x-auto pt-4">
                <.table
                  id={"#{Macro.underscore(category.label |> String.replace(" ", ""))}_table"}
                  rows={category.attributes}
                >
                  <:col :let={attribute} label={~t"Name"} class="font-semibold">
                    <%= attribute.name %>
                  </:col>
                  <:col :let={attribute} label={~t"Imported"}>
                    <%= attribute.imported %>
                  </:col>
                  <:col :let={attribute} label={~t"Encoded"}>
                    <%= attribute.encoded %>
                  </:col>
                </.table>
              </div>
            </section>
          <% end %>
          <section>
            <.heading
              title={~t"Record encodings"m}
              subtitle={~t"Results by catalog"m}
              size="sm"
              class="px-6 sm:px-8"
            />
            <div class="no-scrollbar overflow-x-auto pt-4">
              <.table id="encoding_result_table" rows={@record_encoding_results}>
                <:col :let={result} label={~t"Catalog"} class="font-semibold">
                  <%= result.catalog %>
                </:col>
                <:col :let={result} label={~t"State"} class="text-center">
                  <.encoding_state_badge reason={result.message} state={result.state} />
                </:col>
                <:col :let={result} label={~t"Created"} class="text-right">
                  <%= format_datetime(result.inserted_at, format: :short) %>
                </:col>
              </.table>
            </div>
          </section>
        </.slideover>
      </:secondary>
    </.page>
    """
  end

  @impl true
  def handle_event("record:select", %{"id" => nil}, socket) do
    socket =
      socket
      |> assign(:selected_record, nil)
      |> assign(:record_encoding_results, nil)
      |> assign(:attrs_in_categories, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("record:select", %{"id" => id}, socket) do
    record = get_record(id)

    socket =
      socket
      |> assign(:selected_record, record)
      |> assign(:record_encoding_results, RecordEncodingResult.filter_by_record!(id))
      |> assign(:attrs_in_categories, attrs_by_category_in_layers(record))

    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:encode", _params, socket) do
    Task.start(fn ->
      collection = socket.assigns.collection

      collection.records
      |> Task.async_stream(&Record.enqueue_encoder!(&1))
      |> Stream.run()

      Collection.touch(collection)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({topic, _event, notification}, socket) do
    id = socket.assigns.collection.id

    cond do
      topic == "record:#{id}:created" -> handle_record_created(notification, socket)
      topic == "record:#{id}:updated" -> handle_record_updated(notification, socket)
      topic == "record:#{id}:destroyed" -> handle_record_destroyed(notification, socket)
      topic == "import:#{id}:updated" -> handle_import_updated(notification, socket)
      topic == "collection:updated:#{id}" -> handle_collection_update(notification, socket)
      true -> {:noreply, socket}
    end
  end

  defp handle_record_created(notification, socket) do
    %Ash.Notifier.Notification{data: record} = notification
    record = Records.load!(record, @load, lazy?: true)
    {:noreply, stream_insert(socket, :results, record)}
  end

  defp handle_record_updated(notification, socket) do
    handle_record_created(notification, socket)
  end

  defp handle_record_destroyed(notification, socket) do
    %Ash.Notifier.Notification{data: record} = notification
    {:noreply, stream_delete(socket, :results, record)}
  end

  defp handle_import_updated(notification, socket) do
    %Ash.Notifier.Notification{data: import} = notification
    {:noreply, assign(socket, :collection, get_collection(import.collection_id))}
  end

  defp handle_collection_update(notification, socket) do
    %Ash.Notifier.Notification{data: collection} = notification
    collection = get_collection(collection.id)

    {:noreply,
     socket
     |> assign(:collection, collection)
     |> assign(:busy, collection.encoding_state in [:queued, :encoding])}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Records"m)
  end

  defp assign_records(socket, params) do
    stream(socket, :results, list_records(params))
  end

  defp list_records(params) do
    opts = DataTable.read_opts(collection_scope(params), params)
    opts = Keyword.put(opts, :load, @load)

    {:ok, result} = Record.read(opts)

    case result do
      %Ash.Page.Offset{results: records} -> records
      records -> records
    end
  end

  defp collection_scope(params) do
    Record |> Ash.Query.filter_input(%{"collection" => %{"id" => params["id"]}})
  end

  defp get_record(id) do
    Record.get_by_id!(id, load: @load)
  end
end
