defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Record.Subscriptions

  import Ash.Expr
  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_light: 2, busy_action: 1, cancel_action: 2]

  import DataAggregatorWeb.CollectionLive.Record.ActivityFeed
  import DataAggregatorWeb.CollectionLive.Record.Components
  import DataAggregatorWeb.CollectionLive.Record.Components.Toolbar, only: [toolbar: 1]
  import DataAggregatorWeb.CollectionLive.Record.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog
  alias Phoenix.LiveView.AsyncResult

  require Ash.Query

  @load [
    :encoded_record,
    :mids_level,
    :iucn_redlist,
    :eve_event_date_presence,
    :iucn_redlist_category_group,
    :loc_decimal_presence,
    :loc_swiss_coordinates_95_presence,
    :loc_swiss_coordinates_03_presence
  ]
  @async_keys [:meta, :results]
  @coordinate_attribute_names ~w(swissCoordinatesLv03_E swissCoordinatesLv03_N swissCoordinatesLv95_E swissCoordinatesLv95_N)

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = get_collection_light(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:collection_type, collection.type)
      |> assign(:selected_record, nil)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> assign_search(nil)
      |> assign(:filters_count, 0)
      |> assign(:show_filters, false)
      |> assign(:show_encode, false)
      |> assign(:show_publication, false)
      |> assign(:show_validation, false)
      |> assign(:record_tab, "data")
      |> assign(:agreed, false)
      |> assign_scope_stats()
      |> subscribe_for_record_updates(connected?(socket))

    {:ok, socket}
  end

  defp assign_scope_stats(socket) do
    %{collection: collection} = socket.assigns

    assign_async(
      socket,
      [:records_count_not_validated, :records_count_not_encoded, :records_count_not_published],
      fn ->
        count_not_encoded =
          Record
          |> Ash.Query.set_tenant(collection)
          |> Ash.Query.filter(expr(not_encoded == true))
          |> Ash.count!()

        count_not_published =
          Record
          |> Ash.Query.set_tenant(collection)
          |> Ash.Query.filter(expr(not_published == true))
          |> Ash.count!()

        count_not_validated =
          Record
          |> Ash.Query.set_tenant(collection)
          |> Ash.Query.filter(expr(not_validated == true))
          |> Ash.count!()

        stats = %{
          records_count_not_validated: count_not_validated,
          records_count_not_encoded: count_not_encoded,
          records_count_not_published: count_not_published
        }

        {:ok, stats}
      end
    )
  end

  @impl true
  def handle_params(params, _url, socket) do
    layer = params |> Map.get("layer", "encoding") |> coalesce_layer()
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    socket
    |> register_async_keys()
    |> start_async(:results, fn ->
      list_records(params, actor, tenant)
    end)
    |> assign(:layer, layer)
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp register_async_keys(socket) do
    @async_keys
    |> Enum.reduce(socket, fn key, acc ->
      assign(acc, key, AsyncResult.loading())
    end)
    |> stream(:results, [])
  end

  defp fail_async_keys(socket, reason) do
    @async_keys
    |> Enum.reduce(socket, fn key, acc ->
      update(acc, key, fn async_result -> AsyncResult.failed(async_result, {:exit, reason}) end)
    end)
    |> noreply()
  end

  @impl true
  def handle_async(:results, {:exit, reason}, socket) do
    fail_async_keys(socket, reason)
  end

  @impl true
  def handle_async(:results, {:ok, fetch_result}, socket) do
    case fetch_result do
      {:ok, {records, meta}} ->
        %{
          results: origin_results,
          meta: origin_meta
        } = socket.assigns

        filters_count = meta |> AshPagify.FilterForm.active_filter_form_fields() |> length()

        socket
        |> assign(:meta, AsyncResult.ok(origin_meta, meta))
        |> assign(:results, AsyncResult.ok(origin_results, :results))
        |> stream(:results, records, reset: true)
        |> assign(:filters_count, filters_count)
        |> assign_search(meta)
        |> noreply()

      {:error, %AshPagify.Meta{errors: []}} ->
        fail_async_keys(socket, ~t"Something went wrong"m)

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{socket.assigns.collection.id}/records")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user} open={@selected_record != nil}>
      <.collection_header
        collection={@collection}
        current={:records}
        current_user={@current_user}
        busy={@busy}
        busy_action={@busy_action}
        meta={@meta.result}
      />

      <.secondary_navigation class="top-[calc(4rem-1px)] sticky">
        <.secondary_navigation_item
          href={path_helper(@collection, @layer, @meta.result)}
          label={~t"Records"m}
          active
        />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/imports"} label={~t"Imports"m} />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/exports"} label={~t"Exports"m} />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/publications"}
          label={~t"Publications"m}
        />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/validations"}
          label={~t"Validations"m}
        />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/image_uploads"}
          label={~t"Image Upload"m}
        />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/published_records"}
          label={~t"Published Records"m}
        />
      </.secondary_navigation>

      <%!-- Stat scopes --%>
      <div :if={@collection.records_count > 0} class="px-6 py-4 md:py-6 lg:px-8">
        <div class="grid grid-cols-2 gap-4 md:gap-6 xl:grid-cols-4">
          <.scope_stat
            href={path_helper(@collection, @layer, @meta.result, %{status: :all})}
            title={~t"All records"m}
            value={1.0}
            desc={
              mgettext("%{record_count} Records",
                record_count: format_number(@collection.records_count)
              )
            }
            active={@meta.ok? && AshPagify.active_scope?(@meta.result.ash_pagify, %{status: :all})}
          />

          <.placeholder_stat
            :if={@records_count_not_encoded.loading}
            title={~t"Not encoded / Incomplete"m}
          />
          <.scope_stat
            :if={@records_count_not_encoded.ok?}
            href={path_helper(@collection, @layer, @meta.result, %{status: :not_encoded})}
            title={~t"Not encoded / Incomplete"m}
            value={
              if @records_count_not_encoded.result == 0,
                do: 0,
                else: @records_count_not_encoded.result / @collection.records_count
            }
            desc={
              mgettext("%{records_count_not_encoded} of %{records_count} Records",
                records_count_not_encoded: format_number(@records_count_not_encoded.result),
                records_count: format_number(@collection.records_count)
              )
            }
            active={
              @meta.ok? && AshPagify.active_scope?(@meta.result.ash_pagify, %{status: :not_encoded})
            }
          />

          <.placeholder_stat :if={@records_count_not_published.loading} title={~t"Not published"m} />
          <.scope_stat
            :if={@records_count_not_published.ok?}
            href={path_helper(@collection, @layer, @meta.result, %{status: :not_published})}
            title={~t"Not published"m}
            value={
              if @records_count_not_published.result == 0,
                do: 0,
                else: @records_count_not_published.result / @collection.records_count
            }
            desc={
              mgettext("%{records_count_not_published} of %{records_count} Records",
                records_count_not_published: format_number(@records_count_not_published.result),
                records_count: format_number(@collection.records_count)
              )
            }
            active={
              @meta.ok? && AshPagify.active_scope?(@meta.result.ash_pagify, %{status: :not_published})
            }
          />

          <.placeholder_stat :if={@records_count_not_validated.loading} title={~t"Not validated"m} />
          <.scope_stat
            :if={@records_count_not_validated.ok?}
            href={path_helper(@collection, @layer, @meta.result, %{status: :not_validated})}
            title={~t"Not validated"m}
            value={
              if @records_count_not_validated.result == 0,
                do: 0,
                else: @records_count_not_validated.result / @collection.records_count
            }
            desc={
              mgettext("%{records_count_not_validated} of %{records_count} Records",
                records_count_not_validated: format_number(@records_count_not_validated.result),
                records_count: format_number(@collection.records_count)
              )
            }
            active={
              @meta.ok? && AshPagify.active_scope?(@meta.result.ash_pagify, %{status: :not_validated})
            }
          />
        </div>
      </div>

      <%!-- Search, filter and actions toolbar --%>
      <.toolbar
        search={@search}
        meta={@meta.result}
        collection={@collection}
        records_count={@collection.records_count}
        filters_count={@filters_count}
        busy={@busy}
        busy_action={@busy_action}
        layer={@layer}
        current_user={@current_user}
      />

      <.table
        loading={@results.loading}
        error={@results.failed != nil}
        opts={[
          no_results_content:
            no_results_content(%{
              collection: @collection,
              current_user: @current_user,
              filters_count: @filters_count,
              meta: @meta.result
            })
        ]}
        path={~p"/datasets/#{@collection.id}/records?layer=#{@layer}"}
        items={@streams.results}
        meta={@meta.result}
        row_click={
          fn {_id, record} ->
            JS.push("record:select", value: %{id: record.id})
          end
        }
      >
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :picture)}
          label={picture_th_label()}
        >
          <div
            class="tooltip tooltip-right cursor-help"
            data-tip={
              if record.encoded_record.mte_associated_media,
                do: ~t"Images available"m,
                else: ~t"No images uploaded yet"m
            }
          >
            <.icon
              name={
                if record.encoded_record.mte_associated_media,
                  do: "hero-camera-mini",
                  else: "hero-camera"
              }
              class={
                class_names([
                  "size-5",
                  record.encoded_record.mte_associated_media === nil && "text-base-content",
                  record.encoded_record.mte_associated_media !== nil && "text-success"
                ])
              }
            />
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :iucn_redlist)}
          field={:iucn_redlist}
          label={iucn_redlist_th_label()}
          directions={{:asc, :desc_nils_last}}
        >
          <div
            class="tooltip tooltip-right cursor-help"
            data-tip={
              if record.iucn_redlist,
                do: ~t"According to IUCN an endangered species"m,
                else: ~t"According to IUCN not an endangered species"m
            }
          >
            <.icon
              name={if record.iucn_redlist, do: "hero-flag-mini", else: "hero-flag"}
              class={
                class_names([
                  "size-5",
                  record.iucn_redlist == false && "text-base-content",
                  record.iucn_redlist == true && "text-error"
                ])
              }
            />
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_type_status)}
          field={:idf_type_status}
          label={~t"Typus"m}
        >
          {encoded_attribute(record, :idf_type_status, @layer)}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :tax_scientific_name)}
          field={:tax_scientific_name}
          label={get_dwc_field(:tax_scientific_name)}
        >
          {encoded_attribute(record, :tax_scientific_name, @layer)}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_verbatim_identification)}
          field={:idf_verbatim_identification}
          label={get_dwc_field(:idf_verbatim_identification)}
        >
          {encoded_attribute(record, :idf_verbatim_identification, @layer)}
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
          {encoded_attribute(record, :eve_field_number, @layer)}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_recorded_by)}
          field={:mte_recorded_by}
          label={get_dwc_field(:mte_recorded_by)}
        >
          {encoded_attribute(record, :mte_recorded_by, @layer)}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_identified_by)}
          field={:idf_identified_by}
          label={get_dwc_field(:idf_identified_by)}
        >
          {encoded_attribute(record, :idf_identified_by, @layer)}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_event_date)}
          field={:eve_event_date}
          label={get_dwc_field(:eve_event_date)}
        >
          {encoded_attribute(record, :eve_event_date, @layer)}
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_state_province)}
          field={:loc_state_province}
          label={place_th_label()}
        >
          <div>{encoded_attribute(record, :loc_state_province, @layer)}</div>
          <div class="text-base-content/75 text-xs">
            {encoded_attribute(record, :loc_country_code, @layer)}
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
            {format_coordinate(encoded_attribute(record, :loc_decimal_latitude, @layer))}
          </div>
          <div>
            {format_coordinate(encoded_attribute(record, :loc_decimal_longitude, @layer))}
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :state)}
          field={:state}
          label={~t"Encoding"m}
          class="text-center"
        >
          <.encoding_state_badge state={record.state} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :publication_status)}
          field={:publication_status}
          label={~t"Publication status"m}
          class="text-center"
        >
          <.publication_state_badge state={record.publication_status} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :oth_swiss_species_center)}
          field={:oth_swiss_species_center}
          label={~t"Swiss Registry"m}
          class="text-center"
        >
          <.swiss_species_center_badge
            registered={record.encoded_record.oth_swiss_species_registered}
            center={record.encoded_record.oth_swiss_species_center}
          />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :validation_status)}
          field={:validation_status}
          label={~t"Validation status"m}
          class="text-center"
        >
          <%= unless record.encoded_record.oth_swiss_species_registered == false do %>
            <.validation_state_badge state={record.validation_status} />
          <% end %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mids_level)}
          field={:mids_level}
          label={~t"Quality"m}
          class="text-center"
        >
          <.mids_level_indicator level={record.mids_level} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :updated_at)}
          field={:updated_at}
          label={~t"Updated At"m}
          class="text-end"
        >
          {format_datetime(record.updated_at, format: :medium)}
        </:col>

        <:action
          :let={{_id, record}}
          :if={Record.can_create?(@current_user, reuse_values?: true)}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <.table_action_button
            phx-click={JS.push("record:delete", value: %{id: record.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_record_alert"
            disabled={@busy}
            icon="hero-trash-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta.result} path={~p"/datasets/#{@collection.id}/records?layer=#{@layer}"} />

      <:secondary>
        <.slideover
          title={@selected_record != nil && encoded_attribute(@selected_record, :tax_scientific_name)}
          open={@selected_record != nil}
          on_cancel={JS.push("record:select", value: %{id: nil})}
          size="xl"
          gradient={false}
          class=""
        >
          <:additional_header_content>
            <.slideover_subtitle
              text={@selected_record.mte_catalog_number}
              gbif_id={@selected_record.oth_gbif_id}
              publication_status={@selected_record.publication_status}
            />
            <div class="mt-4 flex space-x-2 max-sm:hidden">
              <.encoding_state_badge state={@selected_record.state} tooltip={false} />
              <.publication_state_badge state={@selected_record.publication_status} tooltip={false} />
              <%= unless @selected_record.encoded_record.oth_swiss_species_registered == false do %>
                <.validation_state_badge state={@selected_record.validation_status} tooltip={false} />
              <% end %>
            </div>
          </:additional_header_content>

          <.secondary_navigation class="sticky top-0 border-t-0">
            <.secondary_navigation_item
              label={~t"Data"m}
              on_click="record:set_tab"
              phx-value-tab="data"
              active={@record_tab == "data"}
            />
            <.secondary_navigation_item
              label={~t"Changes"m}
              on_click="record:set_tab"
              phx-value-tab="changes"
              active={@record_tab == "changes"}
            />
            <.secondary_navigation_item
              label={~t"Encodings"m}
              on_click="record:set_tab"
              phx-value-tab="encodings"
              active={@record_tab == "encodings"}
            />
          </.secondary_navigation>
          <div :if={@record_tab == "data"} class="contents">
            <.list class="border-black-white/10 border-b">
              <:item title={~t"Imported"m}>
                {format_datetime(@selected_record.last_imported_at)}
              </:item>
              <:item title={~t"Last Changes"m}>
                {format_datetime(@selected_record.updated_at)}
              </:item>
              <:item title={~t"Quality"m}>
                <.mids_level_indicator level={@selected_record.mids_level} />
              </:item>
              <:item title={~t"Swiss Registry"m}>
                <.swiss_species_center_badge
                  registered={@selected_record.encoded_record.oth_swiss_species_registered}
                  center={@selected_record.encoded_record.oth_swiss_species_center}
                />
              </:item>
            </.list>
            <div :if={@selected_record.encoded_record.mte_associated_media} class="pb-4">
              <.first_associated_media
                associated_media={@selected_record.encoded_record.mte_associated_media}
                class="border-black-white/10 border-b py-8"
              />
            </div>
            <%= for category <- @attrs_in_categories do %>
              <details class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:first:border-t lg:pl-4">
                <summary class="collapse-title">
                  {category.label}
                </summary>
                <div class="collapse-content">
                  <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                    {category.description}
                  </p>
                  <.table
                    opts={[
                      container_attrs: [class: "overflow-x-auto -mx-6 lg:-mx-8 pb-4"],
                      tbody_td_attrs: [
                        class: "first:pl-6 last:pr-6 lg:first:pl-8 lg:last:pr-8 break-all lg:max-w-48"
                      ]
                    ]}
                    id={"#{Macro.underscore(category.label |> String.replace(" ", ""))}_table"}
                    items={category.attributes}
                  >
                    <:col :let={attribute} label={~t"Name"} class="font-semibold">
                      {attribute.name}
                    </:col>
                    <:col :let={attribute} label={~t"Imported"}>
                      {format_value(attribute.imported, attribute.name)}
                    </:col>
                    <:col :let={attribute} label={~t"Encoded"}>
                      {format_value(attribute.encoded, attribute.name)}
                    </:col>
                  </.table>
                </div>
              </details>
            <% end %>
            <details
              :if={Enum.empty?(@selected_record.extra_data) == false}
              class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:bg-base-300/30 open:first:border-t lg:pl-4"
            >
              <summary class="collapse-title">
                {~t"Custom Attributes"m}
              </summary>
              <div class="collapse-content">
                <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                  {~t"Custom attributes are attributes that are not part of the darwin core standard."m}
                </p>
                <.table
                  opts={[
                    container_attrs: [class: "no-scrollbar overflow-x-auto -mx-6 lg:-mx-8 pb-4"]
                  ]}
                  id="custom_attributes_table"
                  items={Enum.map(@selected_record.extra_data, fn {k, v} -> %{name: k, value: v} end)}
                >
                  <:col :let={attribute} label={~t"Name"} class="font-semibold">
                    {attribute.name}
                  </:col>
                  <:col :let={attribute} label={~t"Value"}>
                    {attribute.value}
                  </:col>
                </.table>
              </div>
            </details>
          </div>
          <.activity_feed
            :if={@record_tab == "changes"}
            record={@selected_record}
            tenant={@collection}
          />
          <div :if={@record_tab == "encodings"} class="px-6 pt-4 lg:px-8">
            <h2 class="pb-2">
              {~t"Record encodings"m}
            </h2>
            <div class="">
              <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                <%= if Enum.any?(@record_encoding_results) do %>
                  {~t"Results by catalog"m}
                <% else %>
                  {~t"No encoding results available"m}
                <% end %>
              </p>

              <.table
                opts={[
                  container_attrs: [class: "no-scrollbar overflow-x-auto -mx-6 lg:-mx-8 pb-4"]
                ]}
                id="encoding_result_table"
                items={@record_encoding_results}
              >
                <:col :let={result} label={~t"Catalog"} class="font-semibold">
                  {result.catalog}
                </:col>
                <:col :let={result} label={~t"State"} class="text-center">
                  <.encoding_state_badge reason={result.message} state={result.state} />
                </:col>
                <:col :let={result} label={~t"Created"} class="text-right">
                  {format_datetime(result.inserted_at, format: :short)}
                </:col>
              </.table>
            </div>
          </div>
        </.slideover>
      </:secondary>

      <:portal>
        <.modal
          :if={@meta.ok?}
          id="export_modal"
          show={@live_action == :export}
          size="2xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(path_helper(@collection, @layer, @meta.result))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action == :export}
            module={DataAggregatorWeb.CollectionLive.Export.FormComponent}
            id={:new}
            action={@live_action}
            collection={@collection}
            meta={@meta.result}
            busy={@busy}
            layer={@layer}
            current_user={@current_user}
          />
        </.modal>

        <.modal
          :if={@meta.ok?}
          id="encode_modal"
          size="xl"
          title={~t"Encoding summary"m}
          show={@show_encode}
          responsive
          on_cancel={JS.push("encode:toggle")}
          on_confirm={JS.push("collection:encode")}
        >
          <div :if={@show_encode} class="contents">
            <p class="mb-4 text-sm">
              {mgettext("You're about to encode %{count} records.",
                count: format_number(@meta.result.total_count)
              )}
            </p>
            <p class="text-sm">
              {~t"These records will be encoded and enriched using the following resources."m}
            </p>
            <ul class="mt-2 list-inside list-disc text-sm">
              <li :for={catalog <- Catalog.get_translated_catalogs()} class="text-info">
                <span class="text-base-content">{catalog}</span>
              </li>
            </ul>
            <p class="text-base-content/60 mt-4 text-sm">
              {~t"By clicking"m} <span class="text-base-content italic">{~t"Encode"m}</span>
              {~t"the encoding will be triggered. No further action is required. Please note that this process may take some time."m}
            </p>
          </div>
          <:footer>
            <form method="dialog" class="contents">
              <button type="submit" value="confirm" class="btn btn-primary" disabled={@busy}>
                {~t"Encode"m}
              </button>
              <button class="btn btn-ghost">
                {~t"Cancel"m}
              </button>
            </form>
          </:footer>
        </.modal>

        <.modal
          :if={@meta.ok?}
          id="publication_modal"
          size="2xl"
          class="p-0"
          show={@show_publication}
          responsive
          on_cancel={JS.push("publication:toggle")}
          overflow="manual"
        >
          <.live_component
            :if={@show_publication}
            module={DataAggregatorWeb.CollectionLive.Record.PublicationModal}
            id="publication_modal_component"
            meta={@meta.result}
            collection={@collection}
            current_user={@current_user}
            layer={@layer}
            busy={@busy}
            agreed={@agreed}
          />
        </.modal>

        <.modal
          :if={@meta.ok?}
          id="validation_pub_modal"
          size="xl"
          show={@show_validation}
          responsive
          on_cancel={JS.push("validation:toggle")}
          on_confirm={JS.push("collection:validation_pub")}
          overflow="manual"
        >
          <.live_component
            :if={@show_validation}
            module={DataAggregatorWeb.CollectionLive.Record.ValidationModal}
            id="validation_pub_modal_component"
            meta={@meta.result}
            collection={@collection}
            current_user={@current_user}
            layer={@layer}
            busy={@busy}
          />
        </.modal>

        <.modal
          :if={@show_filters and @meta.ok?}
          id="filters_modal"
          show
          size="3xl"
          responsive
          title={~t"Filters"m}
          on_cancel={JS.push("filter_form:toggle")}
          overflow="manual"
        >
          <.live_component
            module={DataAggregatorWeb.CollectionLive.Record.FilterComponent}
            id="record_filters"
            label={~t"records"m}
            meta={@meta.result}
            collection={@collection}
            path={~p"/datasets/#{@collection}/records?layer=#{@layer}"}
          />
        </.modal>

        <.alert id="confirm_record_alert" size="sm" confirm_button_label={~t"Yes, delete record"m}>
          <p class="text-sm">{~t"This will also delete the following associations:"m}</p>
          <ul class="mt-2 list-inside list-disc text-sm">
            <li class="text-info">
              <span class="text-base-content">{~t"Record encodings"m}</span>
            </li>
            <li class="text-info">
              <span class="text-base-content">{~t"Record encoding results"m}</span>
            </li>
            <li class="text-info">
              <span class="text-base-content">{~t"Record imports"m}</span>
            </li>
            <li class="text-info">
              <span class="text-base-content">{~t"Record images"m}</span>
            </li>
          </ul>
        </.alert>

        <.alert
          id="confirm_cancel_alert"
          size="sm"
          title={~t"Are you sure you want to cancel this action?"m}
          confirm_button_label={~t"Yes, confirm"m}
          cancel_button_label={~t"No"m}
        />
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("collection:cancel", %{"id" => id}, socket) do
    cancel_action(id, socket)
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
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    record = get_record(id, actor, tenant)

    socket =
      socket
      |> assign(:selected_record, record)
      |> assign(
        :record_encoding_results,
        RecordEncodingResult.filter_by_record!(id, tenant: tenant)
      )
      |> assign(:attrs_in_categories, attrs_by_category(record, tenant))

    {:noreply, socket}
  end

  @impl true
  def handle_event("record:delete", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    record = Record.get_by_id!(id, actor: actor, tenant: tenant)
    :ok = Record.destroy(record, actor: actor)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Record deleted successfully"m)
     |> assign(:selected_record, nil)
     |> stream_delete(:results, record)}
  end

  @impl true
  def handle_event("record:set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :record_tab, tab)}
  end

  @impl true
  def handle_event("encode:toggle", _, socket) do
    socket = update(socket, :show_encode, &(!&1))
    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:encode", _params, socket) do
    %{collection: collection, meta: %{result: %{ash_pagify: ash_pagify}}, layer: layer} =
      socket.assigns

    actor = get_actor(socket)
    collection = Collection.get_by_id!(collection.id, load: [:encoding], actor: actor)
    socket = update(socket, :show_encode, &(!&1))

    encoding_query = filter_map(ash_pagify, %{collection: %{id: %{eq: collection.id}}}, layer)

    case Collection.enqueue_encoding(collection, encoding_query, actor: actor) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, ~t"Encoding started in background"m)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"An encoding for this dataset is already in process"m)}
    end
  end

  @impl true
  def handle_event("publication:toggle", _, socket) do
    socket =
      socket
      |> update(:show_publication, &(!&1))
      |> assign(:agreed, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validation:toggle", _, socket) do
    socket = update(socket, :show_validation, &(!&1))

    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:validation_pub", _params, socket) do
    %{collection: collection, meta: %{result: %{ash_pagify: ash_pagify}}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:validation_query], lazy?: true, actor: actor)

    validation_query = filter_map(ash_pagify, collection.validation_query, socket.assigns.layer)

    count_query =
      Record
      |> AshPagify.query_for_filters_map(validation_query)
      |> Ash.Query.set_tenant(collection)

    case create_and_enqueue(collection, validation_query, count_query, :validation, actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> update(:show_validation, &(!&1))
         |> put_flash(:info, ~t"Validation started in background"m)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"An validation for this dataset is already in process"m)}
    end
  end

  @impl true
  def handle_event("collection:export", _params, socket) do
    {:noreply, assign(socket, :live_action, :export)}
  end

  @impl true
  def handle_event("filter_form:toggle", _, socket) do
    socket = update(socket, :show_filters, &(!&1))
    {:noreply, socket}
  end

  @impl true
  def handle_event("search:reset", %{"search" => params}, socket) do
    if (params["query"] == "" and coalesce_search(socket.assigns.meta.result.current_search) != "") or
         params["_unused_query"] == "" do
      update_and_patch_search(socket, "")
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search:apply", %{"search" => params}, socket) do
    if params["query"] == coalesce_search(socket.assigns.meta.result.current_search) do
      {:noreply, socket}
    else
      update_and_patch_search(socket, params["query"])
    end
  end

  @impl true
  def handle_event("toggle:agree", _, socket) do
    {:noreply, update(socket, :agreed, &(!&1))}
  end

  @impl true
  def handle_info({"filter_form:submit", _meta}, socket) do
    {:noreply, assign(socket, :show_filters, false)}
  end

  defp create_and_enqueue(collection, query, _count_query, :validation, actor) do
    Collection.start_validations(collection, query, actor: actor, tenant: collection)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Dataset Records"m)
  end

  defp list_records(params, actor, tenant, opts \\ []) do
    opts = Keyword.put(opts, :actor, actor)
    opts = Keyword.put(opts, :tenant, tenant)
    opts = maybe_put_tsvector(Map.get(params, "layer"), opts)

    record_select =
      [
        :id,
        :tax_scientific_name,
        :mte_catalog_number,
        :occ_occurrence_id,
        :mte_associated_media,
        :idf_type_status,
        :idf_verbatim_identification,
        :occ_occurrence_id,
        :mte_catalog_number,
        :eve_field_number,
        :mte_recorded_by,
        :idf_identified_by,
        :eve_event_date,
        :loc_state_province,
        :loc_country_code,
        :loc_verbatim_elevation,
        :loc_minimum_elevation_in_meters,
        :loc_maximum_elevation_in_meters,
        :loc_decimal_latitude,
        :loc_decimal_longitude,
        :state,
        :publication_status,
        :validation_status,
        :updated_at
      ]

    opts =
      Keyword.put(opts, :load, [
        :mids_level,
        :iucn_redlist,
        :encoded_record
      ])

    query =
      Ash.Query.select(
        Record,
        record_select
      )

    AshPagify.validate_and_run(query, params, opts, params["id"])
  end

  defp get_record(id, actor, tenant) do
    Record.get_by_id!(id, load: @load, actor: actor, tenant: tenant)
  end

  defp assign_search(socket, nil) do
    assign(socket, :search, to_form(%{"query" => ""}, as: :search))
  end

  defp assign_search(socket, %AshPagify.Meta{current_search: search}) do
    search = to_form(%{"query" => coalesce_search(search)}, as: :search)
    assign(socket, :search, search)
  end

  defp update_and_patch_search(socket, query) do
    if String.length(query) > 0 && String.length(query) < 3 do
      {:noreply, socket}
    else
      %{meta: %{result: meta}, layer: layer, collection: collection} = socket.assigns

      ash_pagify = AshPagify.set_search(meta.ash_pagify, query)
      meta = %{meta | ash_pagify: ash_pagify}

      path = path_helper(collection, layer, meta)

      socket
      |> push_patch(to: path)
      |> noreply()
    end
  end

  defp format_value(value, attribute_name) when attribute_name in @coordinate_attribute_names do
    case format_coordinate(value) do
      value when is_float(value) -> Float.round(value, 2)
      value -> value
    end
  end

  defp format_value(%DateTime{} = value, "swissSpeciesRegisteredAt"), do: format_datetime(value, format: :short)

  defp format_value(value, _) when is_map(value), do: format_map(value)
  defp format_value(value, _), do: value

  defp coalesce_search(nil), do: ""
  defp coalesce_search(search), do: search

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

  attr :collection_id, :string

  defp no_results_content(%{filters_count: 0} = assigns) do
    ~H"""
    <%= cond do %>
      <% not AshPagify.active_scope?(@meta.ash_pagify, %{status: :all}) -> %>
        <.empty_state
          title={~t"No records found"m}
          description={~t"Try with a different scope"m}
          icon="hero-magnifying-glass"
        />
      <% Collection.can_set_importing?(@current_user, @collection) -> %>
        <.empty_state
          title={~t"No records"m}
          description={~t"Get started by importing new data"m}
          label={~t"Import data"m}
          icon="hero-bug-ant"
          href={~p"/datasets/#{@collection.id}/imports/new"}
          action_icon="hero-arrow-up-tray"
        />
      <% true -> %>
        <.empty_state
          title={~t"No records found"m}
          description={~t"There are no records yet for your institution"m}
          icon="hero-magnifying-glass"
        />
    <% end %>
    """
  end

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No records found"m}
      description={~t"Try with a different filter"m}
      icon="hero-magnifying-glass"
    />
    """
  end

  defp coalesce_layer(layer) when layer in ~w(validation encoding import), do: layer
  defp coalesce_layer(_), do: "validation"

  def picture_th_label(assigns \\ %{}) do
    ~H"""
    <.icon name="hero-camera" class="size-5" />
    """
  end

  def iucn_redlist_th_label(assigns \\ %{}) do
    ~H"""
    <.icon name="hero-flag" class="size-5" />
    """
  end
end
