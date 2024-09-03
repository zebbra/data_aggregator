defmodule DataAggregatorWeb.RecordLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.CollectionLive.Encoding.Components
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.RecordLive.Helpers,
    only: [attrs_by_category_in_layers: 1, encoded_attribute: 2, get_dwc_field: 1]

  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record

  @load [:collection, :encoded_record]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_records(params, get_actor(socket)) do
      {:ok, {records, meta}} ->
        socket =
          socket
          |> assign(meta: meta)
          |> stream(:results, records, reset: true)
          |> assign(selected_record: nil)
          |> apply_action(socket.assigns.live_action, params)

        {:noreply, socket}

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/records")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="records" current_user={@current_user} open={@selected_record != nil}>
      <.page_header class="px-6 pb-4 pt-1 lg:px-8 md:py-6"><%= ~t"Records"m %></.page_header>
      <.table
        opts={[
          container_attrs: [class: "no-scrollbar overflow-x-auto pb-4"],
          no_results_content: no_results_content()
        ]}
        path={~p"/records"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, record} ->
            JS.push("record:select", value: %{id: record.id})
          end
        }
      >
        <:col
          :let={{_id, record}}
          field={:mte_catalog_number}
          label={get_dwc_field(:mte_catalog_number)}
          class="font-semibold"
        >
          <%= record.mte_catalog_number %>
        </:col>
        <:col
          :let={{_id, record}}
          field={:tax_scientific_name}
          label={get_dwc_field(:tax_scientific_name)}
        >
          <%= encoded_attribute(record, :tax_scientific_name) %>
        </:col>
        <:col :let={{_id, record}} label={get_dwc_field(:tax_genus)}>
          <%= encoded_attribute(record, :tax_genus) %>
        </:col>
        <:col :let={{_id, record}} label={get_dwc_field(:tax_family)}>
          <%= encoded_attribute(record, :tax_family) %>
        </:col>
        <:col :let={{_id, record}} label={get_dwc_field(:tax_order)}>
          <%= encoded_attribute(record, :tax_order) %>
        </:col>
        <:col :let={{_id, record}} label={get_dwc_field(:tax_class)}>
          <%= encoded_attribute(record, :tax_class) %>
        </:col>
        <:col :let={{_id, record}} label={get_dwc_field(:tax_phylum)}>
          <%= encoded_attribute(record, :tax_phylum) %>
        </:col>
        <:col :let={{_id, record}} field={:state} label={~t"Encoding"m} class="text-center">
          <.encoding_state_badge state={record.state} />
        </:col>
        <:col :let={{_id, record}} label={~t"Collection"m}>
          <.link
            navigate={~p"/collections/#{record.collection}/records"}
            class="link link-primary link-hover font-semibold rounded-md"
          >
            <%= record.collection.name %>
          </.link>
        </:col>
        <:col :let={{_id, record}} field={:updated_at} label={~t"Updated At"m} class="text-end">
          <%= format_datetime(record.updated_at, format: :medium) %>
        </:col>
      </.table>
      <.pagination meta={@meta} path={~p"/records"} />

      <:secondary>
        <.slideover
          title={@selected_record != nil && encoded_attribute(@selected_record, :tax_scientific_name)}
          subtitle={~t"Characteristics according to the darwin core standard"m}
          open={@selected_record != nil}
          on_cancel={JS.push("record:select", value: %{id: nil})}
          size="xl"
        >
          <%= for category <- @attrs_in_categories do %>
            <details class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:bg-base-300/30 open:first:border-t lg:pl-4">
              <summary class="collapse-title">
                <%= category.label %>
              </summary>
              <div class="collapse-content">
                <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                  <%= category.description %>
                </p>
                <.table
                  opts={[container_attrs: [class: "no-scrollbar overflow-x-auto -mx-6 lg:-mx-8 pb-4"]]}
                  id={"#{Macro.underscore(category.label |> String.replace(" ", ""))}_table"}
                  items={category.attributes}
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
            </details>
          <% end %>
          <details class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:bg-base-300/30 lg:pl-4">
            <summary class="collapse-title">
              <%= ~t"Record encodings"m %>
            </summary>
            <div class="collapse-content">
              <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                <%= ~t"Results by catalog"m %>
              </p>

              <.table
                opts={[container_attrs: [class: "no-scrollbar overflow-x-auto -mx-6 lg:-mx-8 pb-4"]]}
                id="encoding_result_table"
                items={@record_encoding_results}
              >
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
          </details>
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

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Records"m)
  end

  defp list_records(params, actor, opts \\ [load: @load]) do
    opts = Keyword.put(opts, :actor, actor)
    AshPagify.validate_and_run(Record, params, opts)
  end

  defp get_record(id) do
    Record.get_by_id!(id, load: @load)
  end

  def no_results_content(assigns \\ %{}) do
    ~H"""
    <.empty_state
      title={~t"No records"m}
      description={~t"Get started by importing a new dataset."m}
      label={~t"Import"m}
      icon="hero-bug-ant"
      href={~p"/collections"}
    />
    """
  end
end
