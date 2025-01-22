defmodule DataAggregatorWeb.CollectionLive.Import.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Import.Subscriptions

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_light: 2, cancel_action: 2, busy_action: 1]

  import DataAggregatorWeb.CollectionLive.Import.Components,
    only: [import_state_badge: 1, attribute_badge: 1]

  import DataAggregatorWeb.CollectionLive.Import.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @load load()
  @load_import load_all()

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    collection = get_collection_light(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(selected_import: nil)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> assign(show_error_log_preview: false)
      |> subscribe_for_import_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case list_imports(params, actor, tenant) do
      {:ok, {records, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, records, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, %AshPagify.Meta{errors: []}} ->
        raise ~t"Something went wrong"m

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/imports")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user} open={@selected_import != nil}>
      <.collection_header
        collection={@collection}
        current={:imports}
        current_user={@current_user}
        meta={@meta}
        busy={@busy}
        busy_action={@busy_action}
      />
      <.secondary_navigation class="top-[calc(4rem-1px)] sticky">
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/records"} label={~t"Records"m} />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/imports"}
          label={~t"Imports"m}
          active
        />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/exports"} label={~t"Exports"m} />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/publications"}
          label={~t"Publications and Approvals"m}
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

      <.table
        opts={[
          no_results_content:
            no_results_content(%{collection: @collection, current_user: @current_user})
        ]}
        path={~p"/datasets/#{@collection}/imports"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, import} ->
            JS.push("import:select", value: %{id: import.id})
          end
        }
      >
        <:col :let={{_id, import}} field={:state} label={~t"State"m}>
          <.import_state_badge import={import} />
        </:col>
        <:col :let={{_id, import}} label={~t"File"m}>
          <.file_info attachment={import.attachment} rows={import.rows_count} />
        </:col>
        <:col :let={{_id, import}} label={~t"Size"m}>
          <.attachment_download_badge attachment={import.attachment} />
        </:col>
        <:col :let={{_id, import}} field={:inserted_at} label={~t"Created at"m}>
          {format_datetime(import.inserted_at, format: :short)}
        </:col>
        <:col :let={{_id, import}} field={:created_by} label={~t"Created by"m}>
          {maybe_set_user(import.created_by)}
        </:col>
        <:col :let={{_id, import}} field={:started_at} label={~t"Started at"m}>
          {format_datetime(import.started_at, format: :short)}
          <div :if={import.duration} class="text-base-content/60 text-xs">
            {import.duration}
          </div>
        </:col>
        <:col :let={{_id, import}} field={:started_by} label={~t"Started by"m}>
          {maybe_set_user(import.started_by)}
        </:col>
        <:col
          :let={{_id, import}}
          field={:rows_imported_count}
          label={~t"Records"m}
          class="text-right"
          directions={{:asc_nils_first, :desc_nils_last}}
        >
          <%= if import.rows_imported_count do %>
            {format_number(import.rows_imported_count, format: :short)}
          <% else %>
            0
          <% end %>
        </:col>

        <:action
          :let={{_id, import}}
          :if={Collection.can_set_importing?(@current_user, @collection)}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div
            :if={invalid?(import)}
            class="link tooltip link-hover btn btn-sm btn-circle btn-ghost inline-flex"
            data-tip={~t"Mapping is invalid"m}
          >
            <.icon name="hero-exclamation-circle-mini" class="size-5 text-base-content/75" />
          </div>

          <.table_action_button
            :if={can_run?(import)}
            phx-click="import:run"
            phx-value-id={import.id}
            data-tip={~t"Run"m}
            icon="hero-play-circle-mini"
            disabled={@busy}
          />

          <div class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.table_action_button
              :if={can_edit?(import)}
              patch={build_path(~p"/datasets/#{@collection}/imports/#{import}/edit", @meta)}
              data-tip={~t"Edit"m}
              disabled={@busy}
              icon="hero-pencil-square-mini"
            />
          </div>

          <.table_action_button
            type="button"
            phx-click={JS.push("import:delete", value: %{id: import.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_import_alert"
            disabled={@busy || can_delete?(import) == false}
            icon="hero-trash-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/datasets/#{@collection}/imports"} />

      <:secondary>
        <.slideover
          title={~t"Show import"m}
          subtitle={~t"Import status and mapping details."m}
          open={@selected_import != nil}
          on_cancel={JS.push("import:select", value: %{id: nil})}
          size="xl"
        >
          <.section_heading
            text={~t"Import"m}
            class="border-black-white/10 border-b px-6 pb-6 lg:px-8"
            align_items={
              if @selected_import.state == :imported,
                do: "baseline",
                else: "center"
            }
            size="md"
          >
            <:subtitle>
              <div :if={can_run?(@selected_import)} class="mt-1 flex items-center gap-x-2">
                <span class="text-sm">{~t"State:"m}</span>
                <.import_state_badge import={@selected_import} />
              </div>
            </:subtitle>
            <:actions>
              <button
                :if={can_run?(@selected_import)}
                type="button"
                phx-value-id={@selected_import.id}
                phx-click="import:run"
                disabled={@busy}
                class="btn btn-primary max-sm:btn-sm"
              >
                <.icon name="hero-play-circle-mini" class="size-6" /> {~t"Run"m}
              </button>
              <div :if={invalid?(@selected_import)} class="text-error flex h-8 items-center gap-x-2">
                <.icon name="hero-exclamation-triangle-mini" class="size-6 mt-0.5" />
                <span class="text-sm">{~t"Mapping is invalid"m}</span>
              </div>
              <div
                :if={can_run?(@selected_import) == false && invalid?(@selected_import) == false}
                class="flex items-center gap-x-2"
              >
                <span class="text-sm">{~t"State:"m}</span>
                <.import_state_badge import={@selected_import} />
              </div>
            </:actions>
          </.section_heading>

          <.list>
            <:item title={~t"File"m}>
              <.file_info
                attachment={@selected_import.attachment}
                rows={@selected_import.rows_count}
                badge
              />
            </:item>
            <:item title={~t"Created by"m}>
              {maybe_set_user(@selected_import.created_by)}
            </:item>
            <:item title={~t"Created at"m}>
              {format_datetime(@selected_import.inserted_at)}
            </:item>
            <:item title={~t"Rows"m}>{format_number(@selected_import.rows_count)}</:item>

            <:item title={~t"Validation"m}>
              <div class="flex flex-col">
                <.progress
                  value={@selected_import.validation_progress}
                  max={1}
                  class="progress progress-primary w-full"
                />
                <div>
                  {format_number(@selected_import.rows_validated_count)} / {format_number(
                    @selected_import.rows_count
                  )} {~t"rows"m}
                </div>
                <div :if={@selected_import.rows_invalid_count not in [0, nil]} class="text-error">
                  {~t"invalid rows:"m} {format_number(@selected_import.rows_invalid_count)}
                </div>
              </div>
            </:item>

            <:item title={~t"Error Log"m}>
              <div class="flex flex-col">
                <div :if={@selected_import.rows_invalid_count not in [0, nil]}>
                  <div class="text-error">
                    {~t"detected errors:"m} {format_number(@selected_import.rows_error_count)}
                  </div>
                  <div class="inline-flex gap-1">
                    <.link
                      data-tip={~t"Preview error log"m}
                      class="tooltip gap-x-1 self-center rounded-full bg-blue-100 px-1.5 pb-0.5 text-xs font-medium text-blue-500 opacity-75 hover:opacity-100"
                      phx-click="show:error_log_preview"
                      aria-label={~t"Open error log preview"m}
                    >
                      <.icon name="hero-eye-mini" class="size-3 shrink-0" />
                    </.link>
                    <div class="tooltip flex h-10 self-center" data-tip={~t"Download error log"}>
                      <.file_info
                        show_file_name={false}
                        attachment={@selected_import.error_log}
                        rows={@selected_import.rows_error_count}
                        badge
                      />
                    </div>
                  </div>
                </div>
                <div :if={@selected_import.rows_invalid_count in [0, nil]} class="text-italic">
                  <%= if @selected_import.state == :failed do %>
                    <div class="text-error">
                      {~t"An unknown error occurred"m}
                    </div>
                  <% else %>
                    {~t"No errors found"m}
                  <% end %>
                </div>
              </div>
            </:item>

            <:item title={~t"Imported"m}>
              <div class="flex flex-col">
                <.progress
                  value={@selected_import.import_progress}
                  max={1}
                  class="progress progress-primary w-full"
                />
                <div>
                  {format_number(@selected_import.rows_imported_count)} / {format_number(
                    @selected_import.rows_count
                  )} {~t"rows"m}
                </div>
              </div>
            </:item>

            <:item title={~t"Started by"m}>
              {maybe_set_user(@selected_import.started_by)}
            </:item>
            <:item title={~t"Started at"m}>
              <div :if={@selected_import.finished_at == nil}>
                {format_datetime(@selected_import.started_at)}
              </div>
              <div :if={@selected_import.finished_at != nil}>
                {format_date_interval(@selected_import.started_at, @selected_import.finished_at)}
              </div>
              {@selected_import.duration}
            </:item>
          </.list>

          <.table id="import_mapping_table" items={@selected_import.mappings}>
            <:caption>
              <.section_heading
                text={~t"Mapping"m}
                class="border-black-white/10 border-b px-6 pb-6 text-left lg:px-8"
                align_items="center"
                size="md"
              >
                <:actions :if={can_edit?(@selected_import)}>
                  <.link
                    type="button"
                    patch={
                      build_path(
                        ~p"/datasets/#{@collection}/imports/#{@selected_import}/edit",
                        @meta
                      )
                    }
                    class="btn btn-primary max-sm:btn-sm"
                  >
                    <.icon name="hero-pencil-square-mini" class="size-6" /> {~t"Edit"m}
                  </.link>
                </:actions>
              </.section_heading>
            </:caption>
            <:col :let={column} label={~t"Column"m}>
              <span :if={column.name} class="bg-base-200 inline-flex rounded px-2 py-1 text-xs">
                {column.name}
              </span>
              <span :if={column.name == nil} class="text-error">
                {~t"Mapping is invalid"m}
              </span>
            </:col>
            <:col :let={column} label={~t"Mapped to"m} class="py-5">
              <.attribute_badge column={column} />
            </:col>
          </.table>

          <div class="px-6 py-4 lg:px-8">
            <.section_heading text={~t"Unmapped columns"m} class="pb-4" size="md" />
            <span
              :for={
                col <-
                  @selected_import.columns
                  |> Enum.filter(&(&1.mapped? == false))
                  |> Enum.map(& &1.name)
              }
              class="bg-base-200 mr-2.5 mb-2 inline-flex rounded px-2 py-1 text-sm"
            >
              {col}
            </span>
          </div>

          <:footer :if={Collection.can_set_importing?(@current_user, @collection)}>
            <button
              type="button"
              phx-click={JS.push("import:delete", value: %{id: @selected_import.id})}
              class="btn btn-error max-sm:btn-sm"
              data-confirm={~t"Are you sure?"m}
              data-confirm_id="confirm_import_alert"
              disabled={can_delete?(@selected_import) == false}
            >
              <.icon name="hero-x-circle-mini" class="size-6" /> {~t"Delete"m}
            </button>
          </:footer>
        </.slideover>
      </:secondary>

      <:portal>
        <.modal
          :if={@selected_import != nil and @selected_import.error_log != nil}
          id="import_error_log_preview_modal"
          show={@show_error_log_preview}
          title={~t"Import Errors"}
          responsive
          on_cancel={JS.push("hide:error_log_preview")}
          size="5xl"
        >
          <.table
            opts={[
              container_attrs: [
                class: "overflow-x-auto -mx-6 lg:-mx-8"
              ]
            ]}
            items={error_log_preview_data(@selected_import.error_log)}
          >
            <:col :let={error} label={~t"Catalog Number"m}>
              {error[:catalogNumber]}
            </:col>
            <:col :let={error} label={~t"Scientific Name"m}>
              {error[:scientificName]}
            </:col>
            <:col :let={error} label={~t"Field"}>
              {error[:field]}
            </:col>
            <:col :let={error} label={~t"Value"}>
              {error[:value]}
            </:col>
            <:col :let={error} label={~t"Error message"} class="text-right">
              {error[:message]}
            </:col>
          </.table>

          <:footer reverse={false}>
            <div class="inline-flex gap-2 py-2">
              <.attachment_download_badge attachment={@selected_import.error_log} />
              <span class="text-base/6 self-center text-xs italic">
                {~t"Only the first 100 rows will be shown. Download the file to have the complete log"}
              </span>
            </div>
          </:footer>
        </.modal>

        <.modal
          id="import_modal"
          class="no-scrollbar"
          show={@live_action in [:new, :edit, :summary]}
          size="3xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(build_path(~p"/datasets/#{@collection}/imports", @meta))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :edit, :summary]}
            module={DataAggregatorWeb.CollectionLive.Import.FormComponent}
            id={@import.id || :new}
            action={@live_action}
            import={@import}
            collection={@collection}
            show_validation={Phoenix.Flash.get(@flash, :mapping_error)}
            meta={@meta}
            busy={@busy}
            current_user={@current_user}
          />
        </.modal>

        <.alert
          id="confirm_import_alert"
          size="sm"
          title={~t"Are you sure?"m}
          label={~t"Yes, delete import"m}
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
  def handle_event("import:run", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case id
         |> Import.get_by_id!(actor: actor, tenant: tenant)
         |> Import.enqueue_import(%{started_by_id: actor.id}, actor: actor) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, ~t"Import started in background")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"An import for this dataset is already in process")}
    end
  end

  @impl true
  def handle_event("import:delete", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    import = Import.get_by_id!(id, actor: actor, tenant: tenant)
    :ok = Import.destroy(import, actor: actor)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Import deleted successfully"m)
     |> assign(:selected_import, nil)
     |> stream_delete(:results, import)}
  end

  @impl true
  def handle_event("import:select", %{"id" => nil}, socket) do
    socket =
      assign(socket, :selected_import, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("import:select", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    socket =
      assign(
        socket,
        :selected_import,
        Import.get_by_id!(id, load: @load_import, actor: actor, tenant: tenant)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("show:error_log_preview", _, socket) do
    {:noreply, assign(socket, :show_error_log_preview, true)}
  end

  @impl true
  def handle_event("hide:error_log_preview", _, socket) do
    {:noreply, assign(socket, :show_error_log_preview, false)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Dataset Imports"m)
    |> assign(:import, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Import"m)
    |> assign(:import, %Import{})
  end

  defp apply_action(socket, :edit, %{"import_id" => id}) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    import = Import.get_by_id!(id, load: @load_import, actor: actor, tenant: tenant)

    socket
    |> assign(:page_title, ~t"Edit Import"m)
    |> assign(:selected_import, nil)
    |> assign(:import, import)
  end

  defp apply_action(socket, :summary, %{"id" => collection_id, "import_id" => id}) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    import = Import.get_by_id!(id, load: @load_import, actor: actor, tenant: tenant)

    if Enum.empty?(import.missing_mappings) do
      socket
      |> assign(:page_title, ~t"Import Summary"m)
      |> assign(:import, import)
    else
      socket
      |> put_flash(:mapping_error, true)
      |> push_navigate(to: ~p"/datasets/#{collection_id}/imports/#{import}/edit")
    end
  end

  defp list_imports(params, actor, tenant, opts \\ [load: @load]) do
    opts = Keyword.put_new(opts, :actor, actor)
    opts = Keyword.put_new(opts, :tenant, tenant)
    AshPagify.validate_and_run(Import, params, opts)
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <%= if Collection.can_set_importing?(@current_user, @collection) do %>
      <.empty_state
        title={~t"No imports"m}
        description={~t"Get started by importing a new dataset."m}
        label={~t"Import"m}
        icon="hero-arrow-up-tray"
        href={~p"/datasets/#{@collection}/imports/new"}
      />
    <% else %>
      <.empty_state
        title={~t"No imports"m}
        description={~t"There are no imports yet for your institution"m}
        icon="hero-magnifying-glass"
      />
    <% end %>
    """
  end

  defp error_log_preview_data(error_log) do
    error_log = Ash.load!(error_log, [:url], lazy?: true)

    error_log.url
    |> Explorer.DataFrame.from_csv!(max_rows: 100)
    |> Explorer.DataFrame.to_rows(atom_keys: true)
  end
end
