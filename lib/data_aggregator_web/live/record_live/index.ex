defmodule DataAggregatorWeb.RecordLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Encoding.Components

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.RecordLive.Helpers,
    only: [attrs_by_category_in_layers: 1, encoded_attribute: 2]

  alias DataAggregator.Records
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record

  @load [:collection, :encoded_record]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: Records.count!(Record))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_records(params) do
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
    <.page current="records" open={@selected_record != nil}>
      <.page_header class="px-6 pb-4 pt-1 lg:px-8 md:py-6"><%= ~t"Records"m %></.page_header>
      <div :if={@count > 0} class="no-scrollbar overflow-x-auto pb-4">
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
          <:col :let={{_id, record}} label={~t"Collection"m}>
            <.link
              navigate={~p"/collections/#{record.collection}/records"}
              class="link link-primary link-hover font-semibold rounded-md"
            >
              <%= record.collection.name %>
            </.link>
          </:col>
          <:col :let={{_id, record}} label={~t"Updated At"m} class="text-end">
            <%= format_datetime(record.updated_at, format: :medium) %>
          </:col>
        </.table>
        <div class="border-black-white/10 flex items-center justify-end border-t px-6 pt-4 lg:px-8">
          <Pagify.Components.pagination meta={@meta} path={~p"/records"} />
        </div>
      </div>

      <.empty_state
        :if={@count == 0}
        title={~t"No records"m}
        description={~t"Get started by importing a new dataset."m}
        label={~t"Import"m}
        icon="hero-bug-ant"
        href={~p"/collections"}
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
              <.section_heading
                text={category.label}
                description={category.description}
                size="md"
                class="px-6 lg:px-8"
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
            <.section_heading
              text={~t"Record encodings"m}
              description={~t"Results by catalog"m}
              size="md"
              class="px-6 lg:px-8"
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

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Records"m)
  end

  defp list_records(params, opts \\ [load: @load]) do
    Pagify.validate_and_run(Record, params, opts)
  end

  defp get_record(id) do
    Record.get_by_id!(id, load: @load)
  end
end
