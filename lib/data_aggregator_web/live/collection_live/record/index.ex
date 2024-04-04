defmodule DataAggregatorWeb.CollectionLive.Record.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Components, only: [scope_stat: 1]
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, subscribe_for_collection_updates: 2]

  import DataAggregatorWeb.CollectionLive.Record.Components
  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [subscribe_for_record_updates: 2]
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  import DataAggregatorWeb.RecordLive.Helpers,
    only: [attrs_by_category_in_layers: 1, encoded_attribute: 2]

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregatorWeb.Components.DataTable

  @load [:collection, :encoded_record]

  @polling_interval 5_000

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = get_collection(id)

    socket
    |> assign(:collection, collection)
    |> subscribe_for_record_updates(connected?(socket))
    |> subscribe_for_collection_updates(connected?(socket))
    |> assign_records(params)
    |> assign(selected_record: nil)
    |> assign(:busy, busy?(collection))
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  defp busy?(collection) do
    collection.encoding_state in [:queued, :encoding] or
      collection.records_publishing > 0
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" open={@selected_record != nil}>
      <.collection_header collection={@collection} current={:records} />
      <.secondary_navigation class="sticky top-[calc(4rem-1px)]" gradient>
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/records"}
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
          label={~t"Publications"m}
        />
        <li
          id="dynamic_export_button"
          class="pointer-events-none -my-2 ml-auto w-0 snap-start overflow-hidden opacity-0 transition-opacity duration-150 ease-in-out"
          data-show_y="280,lg:340"
          data-class_list="pointer-events-none w-0 overflow-hidden"
          phx-hook="ShowHideOnScroll"
        >
          <button
            phx-click="collection:export"
            class="btn btn-primary text-primary-content btn-sm"
            disabled={@busy}
          >
            <.icon name="hero-arrow-down-tray" class="size-4" />
            <span class="max-sm:hidden"><%= ~t"Export"m %></span>
          </button>
        </li>
        <li
          id="dynamic_encode_button"
          class="-my-2 hidden snap-start opacity-0 transition-opacity duration-150 ease-in-out"
          data-show_y="280,lg:340"
          phx-hook="ShowHideOnScroll"
        >
          <button
            phx-click="collection:encode"
            class="btn btn-primary text-primary-content btn-sm"
            disabled={@busy}
          >
            <.icon :if={@busy == false} name="hero-puzzle-piece" class="size-4" />
            <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" class="size-4" />
            <span class="max-sm:hidden"><%= ~t"Encode"m %></span>
          </button>
        </li>
        <li
          id="dynamic_add_button"
          class="-my-2 hidden snap-start opacity-0 transition-opacity duration-150 ease-in-out"
          data-show_y="40,sm:60,lg:76"
          phx-hook="ShowHideOnScroll"
        >
          <.link patch={~p"/collections/#{@collection}/imports/new"} class="btn btn-primary btn-sm">
            <.icon name="hero-arrow-up-tray" class="size-4" />
            <span class="max-sm:hidden"><%= ~t"Add"m %></span>
          </.link>
        </li>
      </.secondary_navigation>
      <div :if={@collection.records_count > 0} class="space-y-6 p-6 lg:px-8">
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
          <button
            phx-click={JS.push("collection:export")}
            class="btn btn-primary text-primary-content max-sm:btn-sm"
            disabled={@busy}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_export_alert"
          >
            <.icon name="hero-arrow-down-tray" class="max-sm:size-4" />
            <%= ~t"Export"m %>
          </button>

          <button
            phx-click={JS.push("collection:encode")}
            class="btn btn-primary text-primary-content max-sm:btn-sm"
            disabled={@busy}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_encoding_alert"
          >
            <.icon :if={@busy == false} name="hero-puzzle-piece" class="max-sm:size-4" />
            <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" class="max-sm:size-4" />
            <%= ~t"Encode"m %>
          </button>
          <button
            phx-click={JS.push("collection:fast_track_pub")}
            class="btn btn-primary text-primary-content max-sm:btn-sm"
            disabled={@busy}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_fast_track_pub_alert"
          >
            <.icon :if={@busy == false} name="hero-fire-mini" class="max-sm:size-4" />
            <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" class="max-sm:size-4" />
            <%= ~t"Fast Track Pub."m %>
          </button>
          <button
            phx-click={JS.push("collection:approval_pub")}
            class="btn btn-primary text-primary-content max-sm:btn-sm"
            disabled={@busy}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_approval_pub_alert"
          >
            <.icon :if={@busy == false} name="hero-shield-check" class="max-sm:size-4" />
            <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" class="max-sm:size-4" />
            <%= ~t"Approval Pub."m %>
          </button>
        </div>
      </div>

      <div :if={@collection.records_count > 0} class="no-scrollbar overflow-x-auto py-4">
        <.table
          id="records_table"
          rows={@streams.results}
          row_click={
            fn {_id, record} ->
              JS.push("record:select", value: %{id: record.id})
            end
          }
        >
          <:col :let={{_id, record}} label={~t"Catalog Number"m} class="font-semibold">
            <%= record.mte_catalog_number %>
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
          <:col :let={{_id, record}} label={~t"Fast Track Pub."m} class="text-center">
            <.publication_status_badge state={record.fast_track_status} />
          </:col>
          <:col :let={{_id, record}} label={~t"Approval Pub."m} class="text-center">
            <.publication_status_badge state={record.approval_status} />
          </:col>
          <:col :let={{_id, record}} label={~t"Updated At"m} class="text-end">
            <%= format_datetime(record.updated_at, format: :medium) %>
          </:col>

          <:action :let={{_id, record}} class="flex items-center justify-end gap-x-2">
            <button
              type="button"
              phx-click={JS.push("record:delete", value: %{id: record.id})}
              disabled={record.state in [:encoding, :queued]}
              class="link link-error link-hover tooltip tooltip-error rounded-md disabled:pointer-events-none disabled:opacity-50"
              data-tip={~t"Delete"m}
              data-confirm={~t"Are you sure?"m}
              data-confirm_id="confirm_record_alert"
            >
              <.icon name="hero-x-circle-mini" class="size-6" />
            </button>
          </:action>
        </.table>
      </div>

      <.empty_state
        :if={@collection.records_count == 0}
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

      <.alert id="confirm_record_alert" size="sm">
        <p class="text-sm"><%= ~t"This will also delete the following associations:"m %></p>
        <ul class="mt-2 list-inside list-disc text-sm">
          <li class="text-info">
            <span class="text-base-content"><%= ~t"Record encodings"m %></span>
          </li>
          <li class="text-info">
            <span class="text-base-content"><%= ~t"Record encoding results"m %></span>
          </li>
          <li class="text-info"><span class="text-base-content"><%= ~t"Record imports"m %></span></li>
          <li class="text-info"><span class="text-base-content"><%= ~t"Record images"m %></span></li>
        </ul>
      </.alert>

      <.alert
        id="confirm_export_alert"
        size="sm"
        title={~t"Are you sure?"m}
        text={~t"You're about to export this collection"m}
      >
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

      %{"id" => collection.id}
      |> list_records()
      |> Task.async_stream(&Record.enqueue_encoder!/1)
      |> Stream.run()

      Collection.touch(collection)
    end)

    schedule_encoding_poller()

    {:noreply, socket}
  end

  @impl true
  def handle_event("collection:fast_track_pub", _params, socket) do
    %{collection: collection} = socket.assigns
    collection = Records.load!(collection, [:fast_track_query], lazy?: true)

    publication =
      %{
        name: "pub-#{collection.name}-#{:os.system_time()}",
        channel: :fast_track,
        records_query: collection.fast_track_query,
        collection: collection,
        rows_count: Records.count!(collection.fast_track_query)
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
    %{collection: collection} = socket.assigns
    collection = Records.load!(collection, [:approval_query], lazy?: true)

    publication =
      %{
        name: "pub-#{collection.name}-#{:os.system_time()}",
        channel: :approval,
        records_query: collection.approval_query,
        collection: collection,
        rows_count: Records.count!(collection.approval_query)
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
    %{collection: collection} = socket.assigns
    collection = Records.load!(collection, [:records_to_export_query], lazy?: true)

    export =
      %{
        name: "export-#{collection.name}-#{:os.system_time()}",
        collection: collection,
        mapping: nil,
        records_query: collection.records_to_export_query,
        rows_count: Records.count!(collection.records_to_export_query)
      }
      |> Export.create!()
      |> Export.enqueue!()

    {:noreply,
     socket
     |> assign(:export, export)
     |> push_navigate(to: ~p"/collections/#{collection.id}/exports")}
  end

  @impl true
  def handle_info(:poll_encoding, socket) do
    collection = Collection.get_by_id!(socket.assigns.collection.id, load: [:encoding_state])

    if busy?(collection) do
      schedule_encoding_poller()
      {:noreply, socket}
    else
      {:noreply, push_patch(socket, to: ~p"/collections/#{collection.id}/records")}
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
    Ash.Query.filter_input(Record, %{"collection" => %{"id" => params["id"]}})
  end

  defp get_record(id) do
    Record.get_by_id!(id, load: @load)
  end

  defp schedule_encoding_poller do
    Process.send_after(self(), :poll_encoding, @polling_interval)
  end
end
