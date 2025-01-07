defmodule DataAggregatorWeb.CollectionLive.PublishedRecords.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_light: 2, busy_action: 1]

  import DataAggregatorWeb.CollectionLive.Record.Helpers
  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.Publication.PublishedRecord

  @load [publication: :started_by]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = get_collection_light(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:collection_type, collection.type)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _uri, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case list_published_records(params, actor, tenant) do
      {:ok, {published_records, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, published_records, reset: true)
        |> noreply()

      {:error, %AshPagify.Meta{errors: []}} ->
        raise ~t"Something went wrong"m

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/published_records")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user}>
      <.collection_header
        collection={@collection}
        current={:published_records}
        current_user={@current_user}
        busy={@busy}
        busy_action={@busy_action}
      />
      <.secondary_navigation class="top-[calc(4rem-1px)] sticky">
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/records"}
          label={~t"Records"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/imports"}
          label={~t"Imports"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/exports"}
          label={~t"Exports"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/publications"}
          label={~t"Publications and Approvals"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/image_uploads"}
          label={~t"Image Upload"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/published_records"}
          label={~t"Published Records"m}
          active
        />
      </.secondary_navigation>

      <.table
        opts={[
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/collections/#{@collection}/published_records"}
        items={@streams.results}
        meta={@meta}
      >
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_type_status)}
          field={:idf_type_status}
          label={~t"Typus"m}
        >
          {record.idf_type_status}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :tax_scientific_name)}
          field={:tax_scientific_name}
          label={get_dwc_field(:tax_scientific_name)}
        >
          {record.tax_scientific_name}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_verbatim_identification)}
          field={:idf_verbatim_identification}
          label={get_dwc_field(:idf_verbatim_identification)}
        >
          {record.idf_verbatim_identification}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :occ_occurrence_id)}
          field={:occ_occurrence_id}
          label={get_dwc_field(:occ_occurrence_id)}
        >
          {record.occ_occurrence_id}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_catalog_number)}
          field={:mte_catalog_number}
          label={get_dwc_field(:mte_catalog_number)}
        >
          {record.mte_catalog_number}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_field_number)}
          field={:eve_field_number}
          label={get_dwc_field(:eve_field_number)}
        >
          {record.eve_field_number}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_recorded_by)}
          field={:mte_recorded_by}
          label={get_dwc_field(:mte_recorded_by)}
        >
          {record.mte_recorded_by}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_identified_by)}
          field={:idf_identified_by}
          label={get_dwc_field(:idf_identified_by)}
        >
          {record.idf_identified_by}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_event_date)}
          field={:eve_event_date}
          label={get_dwc_field(:eve_event_date)}
        >
          {record.eve_event_date}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_state_province)}
          field={:loc_state_province}
          label={place_th_label()}
        >
          <div>{record.loc_state_province}</div>
          <div class="text-base-content/75 text-xs">
            {record.loc_country_code}
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_verbatim_elevation)}
          field={:loc_verbatim_elevation}
          label={elevation_th_label()}
        >
          <div :if={record.loc_verbatim_elevation}>{record.loc_verbatim_elevation}</div>
          <div :if={record.loc_minimum_elevation_in_meters}>
            {record.loc_minimum_elevation_in_meters} / {record.loc_maximum_elevation_in_meters}
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_decimal_latitude)}
          field={:loc_decimal_latitude}
          label={coordinates_th_label()}
          directions={{:asc, :desc_nils_last}}
        >
          <div>
            {format_coordinate(record.loc_decimal_latitude)}
          </div>
          <div>
            {format_coordinate(record.loc_decimal_longitude)}
          </div>
        </:col>
        <:col :let={{_id, record}} field={:updated_at} label={~t"Updated At"m} class="text-end">
          {format_datetime(record.updated_at, format: :medium)}
        </:col>
        <:col :let={{_id, record}} label={~t"Published by"m}>
          {maybe_set_user(record.publication.started_by)}
        </:col>
        <:col :let={{_id, record}} label={~t"Publication Id"m}>
          {record.publication_id}
        </:col>
      </.table>

      <.pagination meta={@meta} path={~p"/collections/#{@collection.id}/published_records"} />
    </.page>
    """
  end

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No published Records"m}
      description={~t"Get started by publishing records."m}
      icon="hero-globe-alt"
    />
    """
  end

  def place_th_label(assigns \\ %{}) do
    ~H"""
    {get_dwc_field(:loc_state_province)} <br /> {get_dwc_field(:loc_country_code)}
    """
  end

  def elevation_th_label(assigns \\ %{}) do
    ~H"""
    {get_dwc_field(:loc_verbatim_elevation)}
    """
  end

  def coordinates_th_label(assigns \\ %{}) do
    ~H"""
    {get_dwc_field(:loc_decimal_latitude)} <br /> {get_dwc_field(:loc_decimal_longitude)}
    """
  end

  defp list_published_records(params, actor, tenant, opts \\ [load: @load]) do
    opts = Keyword.put_new(opts, :tenant, tenant)
    opts = Keyword.put_new(opts, :actor, actor)
    AshPagify.validate_and_run(PublishedRecord, params, opts)
  end
end
