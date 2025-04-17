defmodule DataAggregatorWeb.CollectionLive.Validation.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Publication.Subscriptions

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_light: 2, cancel_action: 2, busy_action: 1]

  import DataAggregatorWeb.CollectionLive.Publication.Components,
    only: [publication_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Publication.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  require Ash.Query

  @load load()
  @load_validation load_all()

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    collection = get_collection_light(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(selected_validation: nil)
      |> assign(:busy, collection.busy)
      |> assign(:busy_action, busy_action(collection))
      |> subscribe_for_publication_updates(connected?(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case list_validations(params, actor, tenant) do
      {:ok, {validations, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, validations, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, %AshPagify.Meta{errors: []}} ->
        raise ~t"Something went wrong"m

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets/#{id}/validations")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user} open={@selected_validation != nil}>
      <.collection_header
        collection={@collection}
        current={:validations}
        current_user={@current_user}
        busy={@busy}
        busy_action={@busy_action}
      />
      <.secondary_navigation class="top-[calc(4rem-1px)] sticky">
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/records"} label={~t"Records"m} />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/imports"} label={~t"Imports"m} />
        <.secondary_navigation_item href={~p"/datasets/#{@collection}/exports"} label={~t"Exports"m} />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/publications"}
          label={~t"Publications"m}
        />
        <.secondary_navigation_item
          href={~p"/datasets/#{@collection}/validations"}
          label={~t"Validations"m}
          active
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
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/datasets/#{@collection}/validations"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, validation} ->
            JS.push("validation:select", value: %{id: validation.id})
          end
        }
      >
        <:col :let={{_id, validation}} field={:state} label={~t"State"m}>
          <.publication_state_badge publication={validation} />
        </:col>
        <:col :let={{_id, validation}} field={:center} label={~t"Center"m} class="text-center">
          {validation.center}
        </:col>
        <:col :let={{_id, validation}} label={~t"File"m}>
          <.file_info attachment={validation.attachment} rows={validation.rows_count} />
        </:col>
        <:col :let={{_id, validation}} label={~t"Size"m}>
          <.attachment_download_badge
            :if={validation.attachment != nil}
            attachment={validation.attachment}
          />
        </:col>
        <:col :let={{_id, validation}} field={:started_at} label={~t"Started at"m}>
          {format_datetime(validation.started_at, format: :short)}
          <div :if={validation.duration} class="text-base-content/60 text-xs">
            {validation.duration}
          </div>
        </:col>
        <:col :let={{_id, validation}} field={:started_by} label={~t"Started by"m}>
          {maybe_set_user(validation.started_by)}
        </:col>
        <:col :let={{_id, validation}} field={:rows_count} label={~t"Records"m} class="text-right">
          {format_number(validation.rows_count, format: :short)}
        </:col>

        <:action
          :let={{_id, validation}}
          :if={Collection.can_set_importing?(@current_user, @collection)}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div :if={can_run?(validation)} class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.table_action_button
              phx-click="validation:run"
              phx-value-id={validation.id}
              data-tip={~t"Run"m}
              icon="hero-play-circle-mini"
            />
          </div>
          <.table_action_button
            phx-click={JS.push("validation:delete", value: %{id: validation.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_validation_alert"
            disabled={can_delete?(validation) == false}
            icon="hero-trash-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/datasets/#{@collection}/validations"} />

      <:secondary>
        <.slideover
          title={if @selected_validation != nil, do: @selected_validation.name, else: ~t"Validation"m}
          subtitle={~t"Validation status details."m}
          open={@selected_validation != nil}
          on_cancel={JS.push("validation:select", value: %{id: nil})}
          size="xl"
        >
          <.section_heading
            text={~t"Validation"m}
            class="border-black-white/10 border-b px-6 pb-6 sm:px-8"
            align_items="center"
            size="md"
          >
            <:subtitle>
              <div :if={@selected_validation.state == :pending} class="mt-1 flex items-center gap-x-2">
                <span class="text-sm">{~t"State:"m}</span>
                <.publication_state_badge publication={@selected_validation} />
              </div>
            </:subtitle>
            <:actions>
              <button
                :if={can_run?(@selected_validation)}
                type="button"
                phx-value-id={@selected_validation.id}
                phx-click="validation:run"
                class="btn btn-primary max-sm:btn-sm"
              >
                <.icon name="hero-play-circle-mini" class="size-6" /> {~t"Run"m}
              </button>
              <div :if={can_run?(@selected_validation) == false} class="flex items-center gap-x-2">
                <span class="text-sm">{~t"State:"m}</span>
                <.publication_state_badge publication={@selected_validation} />
              </div>
            </:actions>
          </.section_heading>

          <.list>
            <:item title={~t"Center"m}>
              {@selected_validation.center}
            </:item>
            <:item title={~t"File"m}>
              <.file_info
                attachment={@selected_validation.attachment}
                rows={@selected_validation.rows_count}
                badge
              />
            </:item>
            <:item title={~t"Created at"m}>
              {format_datetime(@selected_validation.inserted_at)}
            </:item>
            <:item title={~t"Rows"m}>{format_number(@selected_validation.rows_count)}</:item>

            <:item title={~t"Done"m}>
              <div class="flex flex-col">
                <.progress
                  value={@selected_validation.publication_progress || 0}
                  max={1}
                  class="progress progress-primary w-full"
                />
                <div>
                  {format_number(@selected_validation.published_count)} / {format_number(
                    @selected_validation.rows_count
                  )} {~t"rows"m}
                </div>
              </div>
            </:item>

            <:item title={~t"Started by"m}>
              {maybe_set_user(@selected_validation.started_by)}
            </:item>
            <:item title={~t"Started at"m}>
              <div :if={@selected_validation.finished_at == nil}>
                {format_datetime(@selected_validation.started_at)}
              </div>
              <div :if={@selected_validation.finished_at != nil}>
                {format_date_interval(
                  @selected_validation.started_at,
                  @selected_validation.finished_at
                )}
              </div>
              {@selected_validation.duration}
            </:item>
          </.list>

          <:footer :if={
            not is_nil(@selected_validation) &&
              Publication.can_destroy?(@current_user, @selected_validation)
          }>
            <button
              type="button"
              phx-click={JS.push("validation:delete", value: %{id: @selected_validation.id})}
              class="btn btn-error max-sm:btn-sm"
              data-confirm={~t"Are you sure?"m}
              data-confirm_id="confirm_validation_alert"
              disbled={can_delete?(@selected_validation) == false}
            >
              <.icon name="hero-x-circle-mini" class="size-6" /> {~t"Delete"m}
            </button>
          </:footer>
        </.slideover>
      </:secondary>

      <:portal>
        <.alert
          id="confirm_validation_alert"
          size="sm"
          title={~t"Are you sure?"m}
          confirm_button_label={~t"Yes, delete validation"m}
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
  def handle_event("validation:run", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    case id
         |> Publication.get_by_id!(actor: actor, tenant: tenant)
         |> Publication.enqueue(%{started_by_id: actor.id}, actor: actor) do
      {:ok, validation} ->
        {:noreply, put_flash(socket, :info, validation_success_message(validation))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"A validation for this dataset is already in process"m)}
    end
  end

  @impl true
  def handle_event("validation:delete", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)
    validation = Publication.get_by_id!(id, actor: actor, tenant: tenant)
    :ok = Publication.destroy(validation, actor: actor, tenant: tenant)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Validation deleted successfully"m)
     |> assign(:selected_validation, nil)
     |> stream_delete(:results, validation)}
  end

  @impl true
  def handle_event("validation:select", %{"id" => nil}, socket) do
    socket =
      assign(socket, :selected_validation, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validation:select", %{"id" => id}, socket) do
    actor = get_actor(socket)
    tenant = get_tenant(socket)

    socket =
      assign(
        socket,
        :selected_validation,
        Publication.get_by_id!(id, load: @load_validation, actor: actor, tenant: tenant)
      )

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Dataset Validations"m)
    |> assign(:validation, nil)
  end

  defp list_validations(params, actor, tenant, opts \\ [load: @load]) do
    query = Ash.Query.filter(Publication, channel == "validation")

    opts = Keyword.put_new(opts, :actor, actor)
    opts = Keyword.put_new(opts, :tenant, tenant)
    AshPagify.validate_and_run(query, params, opts)
  end

  attr :collection, :any

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No validations"m}
      description={~t"Get started by validating records."m}
      icon="hero-globe-alt"
    />
    """
  end

  defp validation_success_message(%{channel: :validation}) do
    ~t"Validation started in background"m
  end

  defp validation_success_message(_), do: ~t"Validation started in background"m
end
