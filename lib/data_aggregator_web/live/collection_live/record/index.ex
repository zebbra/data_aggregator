defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Record.Subscriptions

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, busy_action: 1]

  import DataAggregatorWeb.CollectionLive.Record.ActivityFeed
  import DataAggregatorWeb.CollectionLive.Record.Components
  import DataAggregatorWeb.CollectionLive.Record.Helpers
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

  @load [:collection, :encoded_record, :mids_level, :iucn_redlist]

  @actions [
    {"export", "hero-arrow-down-tray", "collection:export", nil},
    {"encode", "hero-puzzle-piece", "collection:encode", "confirm_encoding_alert"},
    {"publish", "hero-globe-alt", "collection:fast_track_pub", "confirm_fast_track_pub_alert"},
    {"approve", "hero-check-badge", "collection:approval_pub", "confirm_approval_pub_alert"}
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = get_collection(id)

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:collection_type, collection.type)
      |> assign(:selected_record, nil)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> assign(:actions, @actions)
      |> assign(:show_filters, false)
      |> assign(:record_tab, "data")
      |> subscribe_for_record_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    layer = params |> Map.get("layer", "approval") |> coalesce_layer()

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
      <.collection_header
        collection={@collection}
        current={:records}
        disabled={@busy}
        busy={busy?("dataset:import", @busy_action)}
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
      </.secondary_navigation>

      <%!-- Stat scopes --%>
      <div :if={@collection.records_count > 0} class="px-6 py-4 md:py-6 lg:px-8">
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
      <div :if={@collection.records_count > 0} class="flex justify-between px-6 pb-6 lg:px-8">
        <%!-- Search and filter --%>
        <div class="join">
          <%!-- <div>
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
          </button> --%>
          <.dropdown id="layer" class="dropdown-start">
            <:summary>
              <summary
                class="join-item btn btn-outline border-base-content/20 rounded-l-lg border-y max-sm:btn-square max-sm:inline-flex sm:max-sm:tooltip"
                data-tip={current_layer_label(@layer)}
              >
                <.icon :if={@layer == "import"} name="hero-arrow-up-tray" />
                <.icon :if={@layer == "encoding"} name="hero-puzzle-piece" />
                <.icon :if={@layer == "approval"} name="hero-check-badge" />
                <span class="max-sm:hidden"><%= current_layer_label(@layer) %></span>
              </summary>
            </:summary>
            <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-10 mt-14 w-56 gap-1 border p-2 shadow-2xl">
              <li>
                <.link
                  patch={path_helper(@collection, "approval", @meta)}
                  class={@layer == "approval" && "active"}
                >
                  <.icon name="hero-check-badge" class="size-5" />
                  <span class="font-[sans-serif]"><%= current_layer_label("approval") %></span>
                </.link>
              </li>
              <li>
                <.link
                  patch={path_helper(@collection, "encoding", @meta)}
                  class={@layer == "encoding" && "active"}
                >
                  <.icon name="hero-puzzle-piece" class="size-5" />
                  <span class="font-[sans-serif]"><%= current_layer_label("encoding") %></span>
                </.link>
              </li>
              <li>
                <.link
                  patch={path_helper(@collection, "import", @meta)}
                  class={@layer == "import" && "active"}
                >
                  <.icon name="hero-arrow-up-tray" class="size-5" />
                  <span class="font-[sans-serif]"><%= current_layer_label("import") %></span>
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
                "join-item btn btn-outline border-y max-sm:btn-square sm:max-sm:tooltip"
              ]}
              data-tip={~t"Filters"m}
            >
              <.icon name="hero-adjustments-vertical" />
              <span class="max-sm:hidden"><%= ~t"Filters"m %></span>
            </button>
          </div>
        </div>

        <%!-- Action buttons --%>
        <.dropdown id="actions" class="dropdown-end lg:hidden">
          <:summary>
            <summary
              disabled={@busy}
              class="btn btn-outline border-base-content/20 max-lg:inline-flex max-sm:btn-square sm:max-sm:tooltip"
              data-tip={~t"Actions"m}
            >
              <.icon name={if @busy, do: "hero-cog-6-tooth-solid animate-spin", else: "hero-bars-3"} />
              <span class="max-sm:hidden"><%= ~t"Actions"m %></span>
            </summary>
          </:summary>
          <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-20 mt-14 w-44 gap-1 border p-2 shadow-2xl">
            <li :for={{label, icon, action, alert} <- @actions}>
              <button
                phx-click={action}
                data-confirm={alert && ~t"Are you sure?"m}
                data-confirm_id={alert}
              >
                <.icon name={icon} class="size-5" />
                <span class="font-[sans-serif]"><%= action_label(label) %></span>
              </button>
            </li>
          </ul>
        </.dropdown>

        <div class="join max-lg:hidden">
          <button
            :for={{label, icon, action, alert} <- @actions}
            class="join-item btn btn-outline border-base-content/20"
            phx-click={action}
            data-confirm={alert && ~t"Are you sure?"m}
            data-confirm_id={alert}
            disabled={@busy}
          >
            <.icon :if={busy?(action, @busy_action) == false} name={icon} />
            <.icon :if={busy?(action, @busy_action)} name="hero-cog-6-tooth-solid animate-spin" />
            <span class="max-md:hidden"><%= action_label(label) %></span>
          </button>
        </div>
      </div>

      <.table
        opts={[
          no_results_content:
            no_results_content(%{collection_id: @collection.id, filters_count: @filters_count})
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
          field={:mte_associated_media}
          label={picture_th_label()}
        >
          <div
            class="tooltip tooltip-right"
            data-tip={
              if record.mte_associated_media,
                do: ~t"Images available"m,
                else: ~t"No images uploaded yet"m
            }
          >
            <.icon
              name={if record.mte_associated_media, do: "hero-camera-mini", else: "hero-camera"}
              class={
                class_names([
                  "size-5",
                  record.mte_associated_media === nil && "text-base-content",
                  record.mte_associated_media !== nil && "text-success"
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
          label={~t"Scientific Name"m}
        >
          <%= encoded_attribute(record, :tax_scientific_name, @layer) %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_verbatim_identification)}
          field={:idf_verbatim_identification}
          label={~t"Identification (verbatim)"m}
        >
          <%= record.idf_verbatim_identification %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :occ_occurrence_id)}
          field={:occ_occurrence_id}
          label={~t"Occurrence ID"m}
        >
          <%= record.occ_occurrence_id %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_catalog_number)}
          field={:mte_catalog_number}
          label={~t"Catalog ID"m}
        >
          <%= record.mte_catalog_number %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_field_number)}
          field={:eve_field_number}
          label={~t"Field ID"m}
        >
          <%= record.eve_field_number %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :mte_recorded_by)}
          field={:mte_recorded_by}
          label={~t"Collected by"m}
        >
          <%= record.mte_recorded_by %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :idf_identified_by)}
          field={:idf_identified_by}
          label={~t"Identified by"m}
        >
          <%= record.idf_identified_by %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :eve_event_date)}
          field={:eve_event_date}
          label={~t"Date"m}
        >
          <%= format_date(record.eve_event_date, format: :medium) %>
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :loc_state_province)}
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
          :if={CollectionType.visible?(@collection_type, :loc_verbatim_elevation)}
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
          :if={CollectionType.visible?(@collection_type, :loc_decimal_latitude)}
          field={:loc_decimal_latitude}
          label={~t"Coordinates"m}
          directions={{:asc, :desc_nils_last}}
        >
          <div><%= encoded_attribute(record, :loc_decimal_latitude, @layer) %></div>
          <div><%= encoded_attribute(record, :loc_decimal_longitude, @layer) %></div>
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
          <.publication_status_badge state={record.fast_track_status} />
        </:col>
        <:col
          :let={{_id, record}}
          :if={CollectionType.visible?(@collection_type, :approval_status)}
          field={:approval_status}
          label={~t"Approval status"m}
          class="text-center"
        >
          <.publication_status_badge state={record.approval_status} />
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
          subtitle={~t"Characteristics according to the darwin core standard"m}
          open={@selected_record != nil}
          on_cancel={JS.push("record:select", value: %{id: nil})}
          size="xl"
          gradient={false}
          class=""
        >
          <.secondary_navigation class="sticky border-t-0 top-0 mb-6">
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
          </.secondary_navigation>
          <div :if={@record_tab == "data"} class="contents">
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
          </div>
          <.activity_feed :if={@record_tab == "changes"} record={@selected_record} />
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

        <.alert
          id="confirm_encoding_alert"
          size="sm"
          title={~t"Are you sure?"m}
          text={~t"You're about to encode this collection"m}
          label={~t"Yes, encode"m}
          color="primary"
        >
        </.alert>

        <.alert
          id="confirm_fast_track_pub_alert"
          size="sm"
          title={~t"Are you sure?"m}
          text={~t"You're about to publish this collection directly to the Gbif.ch Portal"m}
          label={~t"Yes, publish"m}
          color="primary"
        >
        </.alert>

        <.alert
          id="confirm_approval_pub_alert"
          size="sm"
          title={~t"Are you sure?"m}
          text={~t"You're about to publish this collection to Infospecies for approval"m}
          label={~t"Yes, approve"m}
          color="primary"
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
  def handle_event("record:set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :record_tab, tab)}
  end

  @impl true
  def handle_event("collection:encode", _params, socket) do
    %{collection: collection} = socket.assigns

    collection = Collection.get_by_id!(collection.id, load: [:encoding])

    case Collection.set_encoding(collection) do
      {:ok, %{id: id}} ->
        enqueue_encoder_fn = fn ->
          Record
          |> Ash.Query.filter(collection.id == ^id)
          |> Pagify.validated_query(socket.assigns.meta.pagify)
          |> Records.stream!(page: false)
          |> Stream.map(&Record.enqueue_encoder!/1)
          |> Stream.run()
        end

        if Records.execute_async?() do
          Task.start(enqueue_encoder_fn)
        else
          enqueue_encoder_fn.()
        end

        {:noreply, put_flash(socket, :info, ~t"Encoding started in background"m)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"An encoding for this collection is already in process"m)}
    end
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

    case create_and_enqueue(collection, fast_track_query, count_query, :fast_track) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, ~t"Publication started in background"m)
         |> push_navigate(to: ~p"/collections/#{collection.id}/publications")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"A publication for this collection is already in process"m)}
    end
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

    case create_and_enqueue(collection, approval_query, count_query, :approval) do
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
  def handle_info({"filter_form:submit", _meta}, socket) do
    {:noreply, assign(socket, :show_filters, false)}
  end

  defp create_and_enqueue(collection, query, count_query, :fast_track) do
    %{
      name: "pub-#{collection.name}-#{:os.system_time()}",
      channel: :fast_track,
      records_query: query,
      collection: collection,
      rows_count: Records.count!(count_query)
    }
    |> Publication.create!()
    |> Publication.enqueue()
  end

  defp create_and_enqueue(collection, query, _count_query, :approval) do
    Collection.approve(collection, query)
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

  attr :collection_id, :string

  defp no_results_content(%{filters_count: 0} = assigns) do
    ~H"""
    <.empty_state
      title={~t"No records"m}
      description={~t"Get started by importing a new dataset"m}
      label={~t"Import"m}
      icon="hero-bug-ant"
      href={~p"/collections/#{@collection_id}/imports/new"}
    />
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

  defp current_layer_label("approval"), do: ~t"Approval Layer"m
  defp current_layer_label("encoding"), do: ~t"Encoding Layer"m
  defp current_layer_label("import"), do: ~t"Import Layer"m

  defp coalesce_layer(layer) when layer in ~w(approval encoding import), do: layer
  defp coalesce_layer(_), do: "approval"

  defp action_label("export"), do: ~t"Export"m
  defp action_label("encode"), do: ~t"Encode"m
  defp action_label("publish"), do: ~t"Publish"m
  defp action_label("approve"), do: ~t"Approve"m

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
