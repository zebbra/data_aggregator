defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components, only: [scope_stat: 1]
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, subscribe_for_collection_updates: 2]

  import DataAggregatorWeb.CollectionLive.Record.ActivityFeed
  import DataAggregatorWeb.CollectionLive.Record.Components
  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [subscribe_for_record_updates: 2]
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.RecordLive.Helpers,
    only: [attrs_by_category_in_layers: 1, encoded_attribute: 2, encoded_attribute: 3]

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  require Ash.Query

  @load [:collection, :encoded_record, :mids_level, :paper_trail_versions, :iucn_redlist]

  @polling_interval 5_000

  @actions [
    {~t"Export"m, "hero-arrow-down-tray", "collection:export", nil},
    {~t"Encode"m, "hero-puzzle-piece", "collection:encode", "confirm_encoding_alert"},
    {~t"Publish"m, "hero-globe-alt", "collection:fast_track_pub", "confirm_fast_track_pub_alert"}
    # at the moment there is no approval process, so we just remove the button to avoid confusion
    # {~t"Approve"m, "hero-check-badge", "collection:approval_pub", "confirm_approval_pub_alert"}
  ]

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    collection = get_collection(id)
    layer = Map.get(params, "layer", "approval")

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:selected_record, nil)
      |> assign(:busy, collection.encoding_state in [:queued, :encoding])
      |> assign(:actions, @actions)
      |> assign(:layer, layer)
      |> assign(:show_filters, false)
      |> subscribe_for_record_updates(connected?(socket))
      |> subscribe_for_collection_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    layer = Map.get(params, "layer", "approval")

    case list_records(params) do
      {:ok, {records, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, records, reset: true)
        |> assign(:layer, layer)
        |> assign(:filters_count, meta |> Pagify.active_filter_form_fields() |> length())
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/records")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_record != nil}>
      <.collection_header collection={@collection} current={:records} />

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
      </.secondary_navigation>

      <%!-- Stat scopes --%>
      <div class="px-6 py-4 md:py-6 lg:px-8">
        <div class="grid grid-cols-2 gap-4 md:gap-6 xl:grid-cols-4">
          <.scope_stat
            href={path_helper(@collection, @layer, @meta, %{status: :all})}
            title={~t"All records"m}
            value={1.0}
            desc={@collection.records_count}
            active={Pagify.active_scope?(@meta.pagify, %{status: :all})}
          />
          <.scope_stat
            href={path_helper(@collection, @layer, @meta, %{status: :not_encoded})}
            title={~t"Not encoded"m}
            value={
              if @collection.records_count_not_encoded == 0,
                do: 1,
                else: @collection.records_count_not_encoded / @collection.records_count
            }
            desc={@collection.records_count_not_encoded}
            active={Pagify.active_scope?(@meta.pagify, %{status: :not_encoded})}
          />
        </div>
      </div>

      <%!-- Search, filter and actions toolbar --%>
      <div class="flex justify-between px-6 pb-6 lg:px-8">
        <%!-- Search and filter --%>
        <div class="join">
          <div>
            <div>
              <input
                class="input input-bordered join-item max-sm:max-w-32"
                placeholder={~t"Search"m}
                disabled
              />
            </div>
          </div>
          <button
            data-tip={~t"Columns"m}
            class="join-item btn btn-outline border-base-content/20 btn-disabled border-y max-sm:btn-square sm:max-md:tooltip"
          >
            <.icon name="hero-table-cells" />
            <span class="max-md:hidden"><%= ~t"Columns"m %></span>
          </button>
          <.dropdown id="layer" class="dropdown-end">
            <:summary>
              <summary
                class="join-item btn btn-outline border-base-content/20 border-y max-md:inline-flex max-sm:btn-square sm:max-md:tooltip"
                data-tip={~t"Layer"m}
              >
                <.icon :if={@layer == "original"} name="hero-arrow-up-tray" />
                <.icon :if={@layer == "encoding"} name="hero-puzzle-piece" />
                <.icon :if={@layer == "approval"} name="hero-check-badge" />
                <span class="max-md:hidden"><%= ~t"Layer"m %></span>
              </summary>
            </:summary>
            <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-10 mt-14 w-44 gap-1 border p-2 shadow-2xl">
              <li>
                <.link
                  patch={path_helper(@collection, "original", @meta)}
                  class={@layer == "original" && "active"}
                >
                  <.icon name="hero-arrow-up-tray" class="size-5" />
                  <span class="font-[sans-serif]"><%= ~t"Original"m %></span>
                </.link>
              </li>
              <li>
                <.link
                  patch={path_helper(@collection, "encoding", @meta)}
                  class={@layer == "encoding" && "active"}
                >
                  <.icon name="hero-puzzle-piece" class="size-5" />
                  <span class="font-[sans-serif]"><%= ~t"Encoding"m %></span>
                </.link>
              </li>
              <li>
                <.link
                  patch={path_helper(@collection, "approval", @meta)}
                  class={@layer == "approval" && "active"}
                >
                  <.icon name="hero-check-badge" class="size-5" />
                  <span class="font-[sans-serif]"><%= ~t"Approval"m %></span>
                </.link>
              </li>
            </ul>
          </.dropdown>
          <div class="indicator">
            <span :if={@filters_count > 0} class="indicator-item badge badge-primary">
              <%= @filters_count %>
            </span>
            <button
              phx-click="filter_form:toggle"
              class={[
                if(@filters_count == 0,
                  do: "border-base-content/20",
                  else: "border-primary sm:outline-primary sm:outline sm:hover:outline-none"
                ),
                "join-item btn btn-outline border-y max-sm:btn-square sm:max-md:tooltip"
              ]}
              data-tip={~t"Filters"m}
            >
              <.icon name="hero-adjustments-vertical" />
              <span class="max-md:hidden"><%= ~t"Filters"m %></span>
            </button>
          </div>
        </div>

        <%!-- Action buttons --%>
        <.dropdown id="actions" class="dropdown-end xl:hidden">
          <:summary>
            <summary
              disabled={@busy}
              class="btn btn-outline border-base-content/20 max-lg:inline-flex max-sm:btn-square sm:max-lg:tooltip"
              data-tip={~t"Actions"m}
            >
              <.icon name={if @busy, do: "hero-cog-6-tooth-solid animate-spin", else: "hero-bars-3"} />
              <span class="max-lg:hidden"><%= ~t"Actions"m %></span>
            </summary>
          </:summary>
          <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-10 mt-14 w-44 gap-1 border p-2 shadow-2xl">
            <li :for={{label, icon, action, alert} <- @actions}>
              <button
                phx-click={action}
                data-confirm={alert && ~t"Are you sure?"m}
                data-confirm_id={alert}
              >
                <.icon name={icon} class="size-5" />
                <span class="font-[sans-serif]"><%= label %></span>
              </button>
            </li>
          </ul>
        </.dropdown>

        <div class="join max-xl:hidden">
          <button
            :for={{label, icon, action, alert} <- @actions}
            class="join-item btn btn-outline border-base-content/20"
            phx-click={action}
            data-confirm={alert && ~t"Are you sure?"m}
            data-confirm_id={alert}
            disabled={@busy}
          >
            <.icon :if={@busy == false} name={icon} />
            <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" />
            <span class="max-md:hidden"><%= label %></span>
          </button>
        </div>
      </div>

      <.table
        opts={[
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/collections/#{@collection}/records?layer=#{@layer}"}
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
          :if={CollectionType.visible?(@collection.type, :picture)}
          th_wrapper_attrs={[
            class: "hero-camera size-5 tooltip",
            aria: [hidden: "true"]
          ]}
          class="text-center"
        >
          <div
            :if={record.mte_associated_media === nil}
            class="tooltip tooltip-right"
            data-tip={~t"No images uploaded yet"m}
          >
            <.icon name="hero-camera" class="size-5 text-gray-600" />
          </div>

          <div
            :if={record.mte_associated_media !== nil}
            class="tooltip tooltip-right"
            data-tip={~t"Images available"m}
          >
            <.icon name="hero-camera-mini" class="size-5 text" />
          </div>
        </:col>
        <:col
          :if={CollectionType.visible?(@collection.type, :iucn_redlist)}
          th_wrapper_attrs={[class: "hero-flag size-5", aria: [hidden: "true"]]}
          class="text-center"
        >
          <div
            class="tooltip tooltip-right"
            data-tip={~t"According to IUCN not an endangered species"m}
          >
            <.icon name="hero-flag" class="size-5 text-gray-600" />
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :idf_type_status)}
          field={:idf_type_status}
          label={~t"Typus"m}
        >
          <%= record.idf_type_status %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :tax_scientific_name)}
          field={:tax_scientific_name}
          label={~t"Scientific Name"m}
        >
          <%= encoded_attribute(record, :tax_scientific_name, @layer) %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :idf_verbatim_identification)}
          field={:idf_verbatim_identification}
          label={~t"Identification (verbatim)"m}
        >
          <%= record.idf_verbatim_identification %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :occ_occurrence_id)}
          field={:occ_occurrence_id}
          label={~t"Occurrence ID"m}
        >
          <%= record.occ_occurrence_id %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :mte_catalog_number)}
          field={:mte_catalog_number}
          label={~t"Catalog ID"m}
        >
          <%= record.mte_catalog_number %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :eve_field_number)}
          field={:eve_field_number}
          label={~t"Field ID"m}
        >
          <%= record.eve_field_number %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :mte_recorded_by)}
          field={:mte_recorded_by}
          label={~t"Collected by"m}
        >
          <%= record.mte_recorded_by %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :idf_identified_by)}
          field={:idf_identified_by}
          label={~t"Identified by"m}
        >
          <%= record.idf_identified_by %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :eve_event_date)}
          field={:eve_event_date}
          label={~t"Date"m}
        >
          <%= format_date(record.eve_event_date, format: :medium) %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :loc_state_province)}
          field={:loc_state_province}
          label={~t"Place"m}
        >
          <div><%= encoded_attribute(record, :loc_state_province, @layer) %></div>
          <div class="text-base-content/75 text-xs">
            <%= encoded_attribute(record, :loc_country_code, @layer) %>
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :loc_verbatim_elevation)}
          field={:loc_verbatim_elevation}
          label={~t"Elevation"m}
        >
          <div :if={record.loc_verbatim_elevation}><%= record.loc_verbatim_elevation %></div>
          <div :if={record.loc_minimum_elevation_in_meters}>
            <%= record.loc_minimum_elevation_in_meters %> / <%= record.loc_maximum_elevation_in_meters %>
          </div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :loc_decimal_latitude)}
          field={:loc_decimal_latitude}
          label={~t"Coordinates"m}
          directions={{:asc, :desc_nils_last}}
        >
          <div><%= encoded_attribute(record, :loc_decimal_latitude, @layer) %></div>
          <div><%= encoded_attribute(record, :loc_decimal_longitude, @layer) %></div>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :state)}
          field={:state}
          label={~t"Encoding"m}
          class="text-center"
        >
          <.encoding_state_badge state={record.state} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :fast_track_status)}
          field={:fast_track_status}
          label={~t"Publication status"m}
          class="text-center"
        >
          <.publication_status_badge state={record.fast_track_status} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :approval_status)}
          field={:approval_status}
          label={~t"Approval status"m}
          class="text-center"
        >
          <.publication_status_badge state={record.approval_status} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :mids_level)}
          field={:mids_level}
          label={~t"Quality"m}
          class="text-center"
        >
          <.mids_level_indicator level={record.mids_level} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection.type, :updated_at)}
          field={:updated_at}
          label={~t"Updated At"m}
          class="text-end"
        >
          <%= format_datetime(record.updated_at, format: :medium) %>
        </:col>

        <:action
          :let={{_id, record}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <button
            phx-click={JS.push("record:delete", value: %{id: record.id})}
            disabled={record.state in [:encoding, :queued]}
            class="link tooltip link-hover btn btn-sm btn-circle btn-ghost inline-flex disabled:pointer-events-none disabled:opacity-50"
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_record_alert"
          >
            <.icon name="hero-trash-mini" class="size-5 text-base-content/75" />
          </button>
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/collections/#{@collection}/records?layer=#{@layer}"} />

      <:secondary>
        <.slideover
          title={@selected_record != nil && encoded_attribute(@selected_record, :tax_scientific_name)}
          subtitle={~t"Characteristics according to the darwin core standard"m}
          open={@selected_record != nil}
          on_cancel={JS.push("record:select", value: %{id: nil})}
          size="xl"
        >
          <.tabs>
            <.tab name="slideover_content_tabs" label="" disabled input_class="!ps-0 !pe-5"></.tab>
            <.tab name="slideover_content_tabs" label={~t"Data"m} class="pt-6" checked>
              <%= for category <- @attrs_in_categories do %>
                <details class="collapse collapse-arrow border-black-white/10 rounded-none border-b px-2 open:bg-base-300/30 lg:pl-4">
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
              </details>
            </.tab>
            <.tab name="slideover_content_tabs" label={~t"Changes"m} class="pt-6">
              <.activity_feed record={@selected_record} />
            </.tab>
          </.tabs>
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
            module={DataAggregatorWeb.CollectionLive.Export.Modal}
            id={:new}
            action={@live_action}
            collection={@collection}
            meta={@meta}
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

        <.alert id="confirm_record_alert" size="sm">
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

        <.alert
          id="confirm_encoding_alert"
          size="sm"
          title={~t"Are you sure?"m}
          text={~t"You're about to encode this collection"m}
        >
        </.alert>

        <.alert
          id="confirm_fast_track_pub_alert"
          size="sm"
          title={~t"Are you sure?"m}
          text={~t"You're about to publish this collection directly to the Gbif.ch Portal"m}
        >
        </.alert>

        <.alert
          id="confirm_approval_pub_alert"
          size="sm"
          title={~t"Are you sure?"m}
          text={~t"You're about to publish this collection to Infospecies for approval"m}
        >
        </.alert>
      </:portal>
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
  def handle_event("record:delete", %{"id" => id}, socket) do
    record = Record.get_by_id!(id)
    :ok = Record.destroy(record)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Record deleted successfully"m)
     |> assign(:selected_record, nil)
     |> stream_delete(:results, record)}
  end

  @impl true
  def handle_event("collection:encode", _params, socket) do
    Task.start(fn ->
      %{collection: collection} = socket.assigns
      collection_id = collection.id

      Record
      |> Ash.Query.filter(collection.id == ^collection_id)
      |> Pagify.validated_query(socket.assigns.meta.pagify)
      |> Records.stream!(page: false)
      |> Stream.map(&Record.enqueue_encoder!/1)
      |> Stream.run()

      Collection.touch(collection)
    end)

    schedule_encoding_poller()

    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:fast_track_pub", _params, socket) do
    %{collection: collection, meta: %{pagify: pagify}} = socket.assigns
    collection = Records.load!(collection, [:fast_track_query], lazy?: true)

    fast_track_query =
      Record
      |> Pagify.compile_filters(pagify)
      |> Pagify.merge_filters(collection.fast_track_query)
      |> Map.get(:filters)

    count_query = Ash.Query.filter_input(Record, fast_track_query)

    publication =
      %{
        name: "pub-#{collection.name}-#{:os.system_time()}",
        channel: :fast_track,
        records_query: fast_track_query,
        collection: collection,
        rows_count: Records.count!(count_query)
      }
      |> Publication.create!()
      |> Publication.enqueue!()

    {:noreply,
     socket
     |> assign(:publication, publication)
     |> push_navigate(to: ~p"/collections/#{collection.id}/publications")}
  end

  @impl true
  def handle_event("collection:approval_pub", _params, socket) do
    %{collection: collection, meta: %{pagify: pagify}} = socket.assigns
    collection = Records.load!(collection, [:approval_query], lazy?: true)

    approval_query =
      Record
      |> Pagify.compile_filters(pagify)
      |> Pagify.merge_filters(collection.approval_query)
      |> Map.get(:filters)

    count_query = Ash.Query.filter_input(Record, approval_query)

    publication =
      %{
        name: "pub-#{collection.name}-#{:os.system_time()}",
        channel: :approval,
        records_query: approval_query,
        collection: collection,
        rows_count: Records.count!(count_query)
      }
      |> Publication.create!()
      |> Publication.enqueue!()

    {:noreply,
     socket
     |> assign(:publication, publication)
     |> push_navigate(to: ~p"/collections/#{collection.id}/publications")}
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
  def handle_info({"filter_form:submit", _meta}, socket) do
    {:noreply, assign(socket, :show_filters, false)}
  end

  @impl true
  def handle_info(:poll_encoding, socket) do
    collection = Collection.get_by_id!(socket.assigns.collection.id, load: [:encoding_state])

    if busy?(collection) do
      schedule_encoding_poller()
      {:noreply, socket}
    else
      {:noreply,
       push_patch(socket,
         to: path_helper(collection, socket.assigns.layer, socket.assigns.meta)
       )}
    end
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
     |> assign(:busy, busy?(collection))}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Collection Records"m)
  end

  defp list_records(params, opts \\ [load: @load, action: :by_collection]) do
    Pagify.validate_and_run(Record, params, opts, params["id"])
  end

  defp get_record(id) do
    Record.get_by_id!(id, load: @load)
  end

  defp schedule_encoding_poller do
    Process.send_after(self(), :poll_encoding, @polling_interval)
  end

  defp busy?(collection) do
    collection.encoding_state in [:queued, :encoding] or
      collection.records_publishing > 0
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No records"m}
      description={~t"Get started by importing a new dataset"m}
      label={~t"Import"m}
      icon="hero-bug-ant"
      href={~p"/collections/#{@collection}/imports/new"}
    />
    """
  end

  defp path_helper(collection, layer, meta, scope \\ nil)

  defp path_helper(collection, "approval", meta, nil) do
    build_path(~p"/collections/#{collection}/records", meta)
  end

  defp path_helper(collection, layer, meta, nil) do
    build_path(~p"/collections/#{collection}/records?layer=#{layer}", meta)
  end

  defp path_helper(collection, "approval", meta, scope) do
    build_scope_path(~p"/collections/#{collection}/records", meta, scope)
  end

  defp path_helper(collection, layer, meta, scope) do
    build_scope_path(~p"/collections/#{collection}/records?layer=#{layer}", meta, scope)
  end
end
