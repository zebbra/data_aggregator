defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components, only: [scope_stat: 1]
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record
  alias DataAggregatorWeb.Components.DataTable

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]
  import DataAggregatorWeb.RecordLive.Helpers, only: [attrs_by_category_in_layers: 1]
  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, subscribe_for_updates: 2]

  @load [:collection, :encoded_record]

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
    collection = get_collection(id)

    socket =
      socket
      |> assign(:collection, collection)
      |> assign_records(params)
      |> assign(selected_record: nil)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_record != nil}>
      <.collection_header collection={@collection} current={:records} />
      <div class="p-6 lg:px-8">
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

      <div class="no-scrollbar overflow-x-auto py-4">
        <.table
          id="records-table"
          rows={@streams.results}
          row_click={
            fn {_id, record} ->
              JS.push("select_record", value: %{id: record.id})
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

      <:secondary>
        <.slideover
          title={@selected_record != nil && encoded_attribute(@selected_record, :tax_scientific_name)}
          subtitle={~t"Characteristics according to the darwin core standard"m}
          open={@selected_record != nil}
          on_cancel={JS.push("select_record", value: %{id: nil})}
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
  def handle_event("select_record", %{"id" => nil}, socket) do
    socket =
      socket
      |> assign(:selected_record, nil)
      |> assign(:record_encoding_results, nil)
      |> assign(:attrs_in_categories, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_record", %{"id" => id}, socket) do
    record = get_record(id)

    socket =
      socket
      |> assign(:selected_record, record)
      |> assign(:record_encoding_results, RecordEncodingResult.filter_by_record!(id))
      |> assign(:attrs_in_categories, attrs_by_category_in_layers(record))

    {:noreply, socket}
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
