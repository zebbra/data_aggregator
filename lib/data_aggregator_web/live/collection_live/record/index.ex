defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Record.Subscriptions

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_full: 2, busy_action: 1, cancel_action: 2]

  import DataAggregatorWeb.CollectionLive.Record.ActivityFeed
  import DataAggregatorWeb.CollectionLive.Record.Components
  import DataAggregatorWeb.CollectionLive.Record.Components.Toolbar, only: [toolbar: 1]
  import DataAggregatorWeb.CollectionLive.Record.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.RecordLive.Helpers,
    only: [
      attrs_by_category_in_layers: 1,
      encoded_attribute: 2,
      encoded_attribute: 3,
      get_dwc_field: 1
    ]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  require Ash.Query

  @load [:collection, :encoded_record, :mids_level, :iucn_redlist]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = get_collection_full(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:collection_type, collection.type)
      |> assign(:selected_record, nil)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> assign(:show_filters, false)
      |> assign(:show_encode, false)
      |> assign(:show_fast_track_pub, false)
      |> assign(:show_approval_pub, false)
      |> assign(:record_tab, "data")
      |> assign(:agreed, false)
      |> subscribe_for_record_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    layer = params |> Map.get("layer", "approval") |> coalesce_layer()

    case list_records(params, get_actor(socket)) do
      {:ok, {records, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, records, reset: true)
        |> assign(:layer, layer)
        |> assign(
          :filters_count,
          meta |> AshPagify.FilterForm.active_filter_form_fields() |> length()
        )
        |> assign_search(meta)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/records")}
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
      />

      <.secondary_navigation class="sticky top-[calc(4rem-1px)]">
        <.secondary_navigation_item
          href={path_helper(@collection, @layer, @meta)}
          label={~t"Records"m}
          active
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
      </.secondary_navigation>

      <%!-- Stat scopes --%>
      <div :if={@collection.records_count > 0} class="px-6 py-4 md:py-6 lg:px-8">
        <div class="grid grid-cols-2 gap-4 md:gap-6 xl:grid-cols-4">
          <.scope_stat
            href={path_helper(@collection, @layer, @meta, %{status: :all})}
            title={~t"All records"m}
            value={1.0}
            desc={
              mgettext("%{record_count} Records",
                record_count: format_number(@collection.records_count)
              )
            }
            active={AshPagify.active_scope?(@meta.ash_pagify, %{status: :all})}
          />
          <.scope_stat
            href={path_helper(@collection, @layer, @meta, %{status: :not_encoded})}
            title={~t"Not encoded / Incomplete"m}
            value={
              if @collection.records_count_not_encoded == 0,
                do: 0,
                else: @collection.records_count_not_encoded / @collection.records_count
            }
            desc={
              mgettext("%{records_count_not_encoded} of %{records_count} Records",
                records_count_not_encoded: format_number(@collection.records_count_not_encoded),
                records_count: format_number(@collection.records_count)
              )
            }
            active={AshPagify.active_scope?(@meta.ash_pagify, %{status: :not_encoded})}
          />
          <.scope_stat
            href={path_helper(@collection, @layer, @meta, %{status: :not_published})}
            title={~t"Not published"m}
            value={
              if @collection.records_count_not_published == 0,
                do: 0,
                else: @collection.records_count_not_published / @collection.records_count
            }
            desc={
              mgettext("%{records_count_not_published} of %{records_count} Records",
                records_count_not_published: format_number(@collection.records_count_not_published),
                records_count: format_number(@collection.records_count)
              )
            }
            active={AshPagify.active_scope?(@meta.ash_pagify, %{status: :not_published})}
          />
          <.scope_stat
            href={path_helper(@collection, @layer, @meta, %{status: :not_approved})}
            title={~t"Not approved"m}
            value={
              if @collection.records_count_not_approved == 0,
                do: 0,
                else: @collection.records_count_not_approved / @collection.records_count
            }
            desc={
              mgettext("%{records_count_not_approved} of %{records_count} Records",
                records_count_not_approved: format_number(@collection.records_count_not_approved),
                records_count: format_number(@collection.records_count)
              )
            }
            active={AshPagify.active_scope?(@meta.ash_pagify, %{status: :not_approved})}
          />
        </div>
      </div>

      <%!-- Search, filter and actions toolbar --%>
      <.toolbar
        search={@search}
        meta={@meta}
        collection_id={@collection.id}
        records_count={@collection.records_count}
        filters_count={@filters_count}
        busy={@busy}
        busy_action={@busy_action}
        layer={@layer}
        current_user={@current_user}
      />

      <.table
        opts={[
          no_results_content:
            no_results_content(%{
              collection: @collection,
              current_user: @current_user,
              filters_count: @filters_count,
              meta: @meta
            })
        ]}
        path={~p"/collections/#{@collection.id}/records?layer=#{@layer}"}
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
          :if={CollectionType.visible?(@collection_type, :picture)}
          label={picture_th_label()}
        >
          <div
            class="tooltip tooltip-right"
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
        >
          <div
            class="tooltip tooltip-right"
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
          <%= record.idf_type_status %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :tax_scientific_name)}
          field={:tax_scientific_name}
          label={get_dwc_field(:tax_scientific_name)}
        >
          <%= encoded_attribute(record, :tax_scientific_name, @layer) %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_verbatim_identification)}
          field={:idf_verbatim_identification}
          label={get_dwc_field(:idf_verbatim_identification)}
        >
          <%= record.idf_verbatim_identification %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :occ_occurrence_id)}
          field={:occ_occurrence_id}
          label={get_dwc_field(:occ_occurrence_id)}
        >
          <%= record.occ_occurrence_id %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_catalog_number)}
          field={:mte_catalog_number}
          label={get_dwc_field(:mte_catalog_number)}
        >
          <%= record.mte_catalog_number %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_field_number)}
          field={:eve_field_number}
          label={get_dwc_field(:eve_field_number)}
        >
          <%= record.eve_field_number %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_recorded_by)}
          field={:mte_recorded_by}
          label={get_dwc_field(:mte_recorded_by)}
        >
          <%= record.mte_recorded_by %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_identified_by)}
          field={:idf_identified_by}
          label={get_dwc_field(:idf_identified_by)}
        >
          <%= record.idf_identified_by %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_event_date)}
          field={:eve_event_date}
          label={get_dwc_field(:eve_event_date)}
        >
          <%= record.eve_event_date %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_state_province)}
          field={:loc_state_province}
          label={place_th_label()}
        >
          <div><%= encoded_attribute(record, :loc_state_province, @layer) %></div>
          <div class="text-base-content/75 text-xs">
            <%= encoded_attribute(record, :loc_country_code, @layer) %>
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_verbatim_elevation)}
          field={:loc_verbatim_elevation}
          label={elevation_th_label()}
        >
          <div :if={record.loc_verbatim_elevation}><%= record.loc_verbatim_elevation %></div>
          <div :if={record.loc_minimum_elevation_in_meters}>
            <%= record.loc_minimum_elevation_in_meters %> / <%= record.loc_maximum_elevation_in_meters %>
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
            <%= format_coordinate(encoded_attribute(record, :loc_decimal_latitude, @layer)) %>
          </div>
          <div>
            <%= format_coordinate(encoded_attribute(record, :loc_decimal_longitude, @layer)) %>
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
          :if={CollectionType.visible?(@collection_type, :fast_track_status)}
          field={:fast_track_status}
          label={~t"Publication status"m}
          class="text-center"
        >
          <.publication_state_badge state={record.fast_track_status} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :approval_status)}
          field={:approval_status}
          label={~t"Approval status"m}
          class="text-center"
        >
          <.approval_state_badge state={record.approval_status} />
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
          <%= format_datetime(record.updated_at, format: :medium) %>
        </:col>

        <:action
          :let={{_id, record}}
          :if={Record.can_create?(@current_user)}
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
      <.pagination meta={@meta} path={~p"/collections/#{@collection.id}/records?layer=#{@layer}"} />

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
              occurrence_id={@selected_record.occ_occurrence_id}
              fast_track_status={@selected_record.fast_track_status}
            />
            <div class="mt-4 flex space-x-2">
              <.encoding_state_badge state={@selected_record.state} />
              <.publication_state_badge state={@selected_record.fast_track_status} />
              <.approval_state_badge state={@selected_record.approval_status} />
            </div>
          </:additional_header_content>

          <.secondary_navigation class="sticky border-t-0 top-0">
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
                <%= format_datetime(@selected_record.last_imported_at) %>
              </:item>
              <:item title={~t"Last Changes"m}>
                <%= format_datetime(@selected_record.updated_at) %>
              </:item>
              <:item title={~t"Quality"m}>
                <.mids_level_indicator level={@selected_record.mids_level} />
              </:item>
            </.list>
            <div :if={@selected_record.mte_associated_media} class="pb-4">
              <.first_associated_media
                associated_media={@selected_record.mte_associated_media}
                class="border-black-white/10 border-b py-8"
              />
            </div>
            <%= for category <- @attrs_in_categories do %>
              <details
                :if={category_has_data?(category)}
                class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:first:border-t lg:pl-4"
              >
                <summary class="collapse-title">
                  <%= category.label %>
                </summary>
                <div class="collapse-content">
                  <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                    <%= category.description %>
                  </p>
                  <.table
                    opts={[
                      container_attrs: [class: "no-scrollbar overflow-x-auto -mx-6 lg:-mx-8 pb-4"]
                    ]}
                    id={"#{Macro.underscore(category.label |> String.replace(" ", ""))}_table"}
                    items={attributes_with_data(category.attributes)}
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
            <details
              :if={Enum.empty?(@selected_record.extra_data) == false}
              class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:bg-base-300/30 open:first:border-t lg:pl-4"
            >
              <summary class="collapse-title">
                <%= ~t"Custom Attributes"m %>
              </summary>
              <div class="collapse-content">
                <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                  <%= ~t"Custom attributes are attributes that are not part of the darwin core standard."m %>
                </p>
                <.table
                  opts={[
                    container_attrs: [class: "no-scrollbar overflow-x-auto -mx-6 lg:-mx-8 pb-4"]
                  ]}
                  id="custom_attributes_table"
                  items={Enum.map(@selected_record.extra_data, fn {k, v} -> %{name: k, value: v} end)}
                >
                  <:col :let={attribute} label={~t"Name"} class="font-semibold">
                    <%= attribute.name %>
                  </:col>
                  <:col :let={attribute} label={~t"Value"}>
                    <%= attribute.value %>
                  </:col>
                </.table>
              </div>
            </details>
          </div>
          <.activity_feed :if={@record_tab == "changes"} record={@selected_record} />
          <div :if={@record_tab == "encodings"} class="px-6 pt-4 lg:px-8">
            <h2 class="pb-2">
              <%= ~t"Record encodings"m %>
            </h2>
            <div class="">
              <p class="text-base-content/60 text-sm/6 line-clamp-2 max-w-4xl">
                <%= if Enum.any?(@record_encoding_results) do %>
                  <%= ~t"Results by catalog"m %>
                <% else %>
                  <%= ~t"No encoding results available"m %>
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
          </div>
        </.slideover>
      </:secondary>

      <:portal>
        <.modal
          id="export_modal"
          show={@live_action == :export}
          size="2xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(path_helper(@collection, @layer, @meta))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action == :export}
            module={DataAggregatorWeb.CollectionLive.Export.FormComponent}
            id={:new}
            action={@live_action}
            collection={@collection}
            meta={@meta}
            busy={@busy}
            layer={@layer}
          />
        </.modal>

        <.modal
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
              <%= mgettext("You're about to encode %{count} records.",
                count: format_number(@meta.total_count)
              ) %>
            </p>
            <p class="text-sm">
              <%= ~t"These records will be encoded and enriched using the following resources."m %>
            </p>
            <ul class="mt-2 list-inside list-disc text-sm">
              <li :for={catalog <- Catalog.get_translated_catalogs()} class="text-info">
                <span class="text-base-content"><%= catalog %></span>
              </li>
            </ul>
            <p class="text-base-content/60 mt-4 text-sm">
              <%= ~t"By clicking"m %>
              <span class="text-base-content italic"><%= ~t"Encode"m %></span>
              <%= ~t"the encoding will be triggered. No further action is required. Please note that this process may take some time."m %>
            </p>
          </div>
          <:footer>
            <form method="dialog" class="contents">
              <button type="submit" value="confirm" class="btn btn-primary" disabled={@busy}>
                <%= ~t"Encode"m %>
              </button>
              <button class="btn btn-ghost">
                <%= ~t"Cancel"m %>
              </button>
            </form>
          </:footer>
        </.modal>

        <.modal
          id="fast_track_pub_modal"
          size="xl"
          show={@show_fast_track_pub}
          responsive
          on_cancel={JS.push("fast_track_pub:toggle")}
          on_confirm={JS.push("collection:fast_track_pub")}
          overflow="manual"
        >
          <.live_component
            :if={@show_fast_track_pub}
            module={DataAggregatorWeb.CollectionLive.Record.FastTrackPubModal}
            id="fast_track_pub_modal_component"
            meta={@meta}
            collection={@collection}
            current_user={@current_user}
            layer={@layer}
            busy={@busy}
            agreed={@agreed}
          />
        </.modal>

        <.modal
          id="approval_pub_modal"
          size="xl"
          show={@show_approval_pub}
          responsive
          on_cancel={JS.push("approval_pub:toggle")}
          on_confirm={JS.push("collection:approval_pub")}
          overflow="manual"
        >
          <.live_component
            :if={@show_approval_pub}
            module={DataAggregatorWeb.CollectionLive.Record.ApprovalModal}
            id="approval_pub_modal_component"
            meta={@meta}
            collection={@collection}
            current_user={@current_user}
            layer={@layer}
            busy={@busy}
          />
        </.modal>

        <.modal
          :if={@show_filters}
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
            meta={@meta}
            collection_id={@collection.id}
            path={~p"/collections/#{@collection}/records?layer=#{@layer}"}
          />
        </.modal>

        <.alert id="confirm_record_alert" size="sm" label={~t"Yes, delete record"m}>
          <p class="text-sm"><%= ~t"This will also delete the following associations:"m %></p>
          <ul class="mt-2 list-inside list-disc text-sm">
            <li class="text-info">
              <span class="text-base-content"><%= ~t"Record encodings"m %></span>
            </li>
            <li class="text-info">
              <span class="text-base-content"><%= ~t"Record encoding results"m %></span>
            </li>
            <li class="text-info">
              <span class="text-base-content"><%= ~t"Record imports"m %></span>
            </li>
            <li class="text-info">
              <span class="text-base-content"><%= ~t"Record images"m %></span>
            </li>
          </ul>
        </.alert>
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
    record = get_record(id, actor)

    socket =
      socket
      |> assign(:selected_record, record)
      |> assign(:record_encoding_results, RecordEncodingResult.filter_by_record!(id))
      |> assign(:attrs_in_categories, attrs_by_category_in_layers(record))

    {:noreply, socket}
  end

  @impl true
  def handle_event("record:delete", %{"id" => id}, socket) do
    actor = get_actor(socket)
    record = Record.get_by_id!(id, actor: actor)
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
    %{collection: collection, meta: %{ash_pagify: ash_pagify}, layer: layer} = socket.assigns

    actor = get_actor(socket)
    collection = Collection.get_by_id!(collection.id, load: [:encoding], actor: actor)
    socket = update(socket, :show_encode, &(!&1))

    encoding_query = filter_map(ash_pagify, %{collection: %{id: %{eq: collection.id}}}, layer)

    case Collection.enqueue_encoding(collection, encoding_query, actor: actor) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, ~t"Encoding started in background"m)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"An encoding for this collection is already in process"m)}
    end
  end

  @impl true
  def handle_event("fast_track_pub:toggle", _, socket) do
    socket =
      socket
      |> update(:show_fast_track_pub, &(!&1))
      |> assign(:agreed, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:fast_track_pub", _params, socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:fast_track_query], lazy?: true, actor: actor)

    fast_track_query = filter_map(ash_pagify, collection.fast_track_query, socket.assigns.layer)
    count_query = AshPagify.query_for_filters_map(Record, fast_track_query)

    case create_and_enqueue(collection, fast_track_query, count_query, :fast_track, actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:agreed, false)
         |> put_flash(:info, ~t"Publication started in background"m)
         |> push_navigate(to: ~p"/collections/#{collection.id}/publications")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:agreed, false)
         |> put_flash(:error, ~t"A publication for this collection is already in process"m)}
    end
  end

  @impl true
  def handle_event("approval_pub:toggle", _, socket) do
    socket = update(socket, :show_approval_pub, &(!&1))

    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:approval_pub", _params, socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:approval_query], lazy?: true, actor: actor)

    approval_query = filter_map(ash_pagify, collection.approval_query, socket.assigns.layer)
    count_query = AshPagify.query_for_filters_map(Record, approval_query)

    case create_and_enqueue(collection, approval_query, count_query, :approval, actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, ~t"Approval started in background"m)
         |> push_navigate(to: ~p"/collections/#{collection.id}/publications")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"An approval for this collection is already in process"m)}
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
    if (params["query"] == "" and coalesce_search(socket.assigns.meta.current_search) != "") or
         params["_unused_query"] == "" do
      update_and_patch_search(socket, "")
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search:apply", %{"search" => params}, socket) do
    if params["query"] == coalesce_search(socket.assigns.meta.current_search) do
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

  defp create_and_enqueue(collection, query, count_query, :fast_track, actor) do
    %{
      name: "pub-#{collection.name}-#{:os.system_time()}",
      channel: :fast_track,
      records_query: query,
      collection: collection,
      rows_count: Ash.count!(count_query)
    }
    |> Publication.create!(actor: actor)
    |> Publication.enqueue(actor: actor)
  end

  defp create_and_enqueue(collection, query, _count_query, :approval, actor) do
    Collection.approve(collection, query, actor: actor)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Records"m)
  end

  defp list_records(params, actor, opts \\ [load: @load, action: :by_collection]) do
    opts = Keyword.put(opts, :actor, actor)
    opts = maybe_put_tsvector(Map.get(params, "layer"), opts)

    AshPagify.validate_and_run(Record, params, opts, params["id"])
  end

  defp get_record(id, actor) do
    Record.get_by_id!(id, load: @load, actor: actor)
  end

  defp assign_search(socket, %AshPagify.Meta{current_search: search}) do
    search = to_form(%{"query" => coalesce_search(search)}, as: :search)
    assign(socket, :search, search)
  end

  defp update_and_patch_search(socket, query) do
    if String.length(query) > 0 && String.length(query) < 3 do
      {:noreply, socket}
    else
      %{meta: %{ash_pagify: ash_pagify} = meta, layer: layer, collection: collection} =
        socket.assigns

      ash_pagify = AshPagify.set_search(ash_pagify, query)
      meta = %{meta | ash_pagify: ash_pagify}

      path = path_helper(collection, layer, meta)

      socket
      |> push_patch(to: path)
      |> noreply()
    end
  end

  defp coalesce_search(nil), do: ""
  defp coalesce_search(search), do: search

  defp place_th_label(assigns \\ %{}) do
    ~H"""
    <%= get_dwc_field(:loc_state_province) %>
    <br />
    <%= get_dwc_field(:loc_country_code) %>
    """
  end

  defp elevation_th_label(assigns \\ %{}) do
    ~H"""
    <%= get_dwc_field(:loc_verbatim_elevation) %>
    """
  end

  defp coordinates_th_label(assigns \\ %{}) do
    ~H"""
    <%= get_dwc_field(:loc_decimal_latitude) %>
    <br />
    <%= get_dwc_field(:loc_decimal_longitude) %>
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
          description={~t"Get started by importing a new dataset"m}
          label={~t"Import"m}
          icon="hero-bug-ant"
          href={~p"/collections/#{@collection.id}/imports/new"}
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

  defp coalesce_layer(layer) when layer in ~w(approval encoding import), do: layer
  defp coalesce_layer(_), do: "approval"

  defp picture_th_label(assigns \\ %{}) do
    ~H"""
    <.icon name="hero-camera" class="size-5" />
    """
  end

  defp iucn_redlist_th_label(assigns \\ %{}) do
    ~H"""
    <.icon name="hero-flag" class="size-5" />
    """
  end
end
