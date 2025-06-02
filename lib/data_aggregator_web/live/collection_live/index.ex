defmodule DataAggregatorWeb.CollectionLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Subscriptions

  import DataAggregatorWeb.CollectionLive.Components, only: [collection_state_badge: 1]
  import DataAggregatorWeb.CollectionLive.Helpers
  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  alias DataAggregator.Records.Collection

  @load load()

  @impl true
  def mount(_params, _session, socket) do
    {:ok, subscribe_for_collection_updates(socket, connected?(socket))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_collections(params, get_actor(socket)) do
      {:ok, {collections, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, collections, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, %AshPagify.Meta{errors: []}} ->
        raise ~t"Something went wrong"m

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/datasets")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user}>
      <.page_header class="px-6 pt-1 pb-4 md:py-6 lg:px-8">
        {~t"Datasets"m}
        <:actions>
          <%= if Collection.can_create?(@current_user) do %>
            <.link patch={build_path(~p"/datasets/new", @meta)} class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-squares-2x2" class="max-sm:size-4" />
              <span class="max-sm:hidden">{~t"New dataset"m}</span>
              <span class="sm:hidden">{~t"Add"m}</span>
            </.link>
          <% end %>
        </:actions>
      </.page_header>

      <.table
        opts={[
          container_attrs: [
            class: "overflow-x-auto pb-4"
          ],
          no_results_content:
            no_results_content(%{collection: @collection, current_user: @current_user})
        ]}
        path={~p"/datasets"}
        items={@streams.results}
        meta={@meta}
      >
        <:col :let={{_id, collection}} field={:name} label={~t"Name"m}>
          <.link
            navigate={~p"/datasets/#{collection}/records"}
            class="link link-primary link-hover font-semibold"
          >
            {collection.name}
          </.link>
        </:col>
        <:col :let={{_id, collection}} field={:code} label={~t"Code"m}>
          {collection.code}
        </:col>
        <:col :let={{_id, collection}} field={:state} label={~t"State"m} class="text-center">
          <.collection_state_badge collection={collection} />
        </:col>
        <:col
          :let={{_id, collection}}
          field={:grscicoll_institution_code}
          label={~t"Institution Code"m}
        >
          {collection.grscicoll_institution_code}
        </:col>
        <:col :let={{_id, collection}} field={:grscicoll_institution_name} label={~t"Institution"m}>
          {collection.grscicoll_institution_name}
        </:col>
        <:col
          :let={{_id, collection}}
          field={:digitizing_progress}
          label={~t"Progress"m}
          class="text-right"
        >
          <div
            class="tooltip tooltip-primary flex flex-1 items-center"
            data-tip={
                "#{collection.digitizing_progress |> Decimal.from_float() |> Decimal.round(1)}%"}
          >
            <progress
              class="progress progress-primary min-w-32 cursor-help"
              value={collection.digitizing_progress}
              max="100"
            />
          </div>
        </:col>
        <:col
          :let={{_id, collection}}
          field={:records_count}
          label={~t"Records count / est."m}
          class="text-right"
        >
          {inspect(collection.records_count)} / {collection.items_to_digitize}
        </:col>
        <:col :let={{_id, collection}} field={:updated_at} label={~t"Updated At"m} class="text-right">
          {format_datetime(collection.updated_at, format: :short)}
        </:col>

        <:action
          :let={{_id, collection}}
          :if={Collection.can_create?(@current_user)}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <.table_action_button
            :if={
              collection.busy and not collection.deleting and
                Collection.can_cancel_action?(@current_user, collection)
            }
            phx-click={JS.push("collection:cancel", value: %{id: collection.id})}
            data-tip={state_translation(collection.state)}
            data-confirm={~t"Are you sure?"m}
            icon="hero-stop-mini"
            icon_class="bg-error"
          />
          <div class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.table_action_button
              patch={build_path(~p"/datasets/#{collection}/edit", @meta)}
              data-tip={~t"Edit"m}
              disabled={collection.busy}
              icon="hero-pencil-square-mini"
            />
          </div>
          <.table_action_button
            phx-click={JS.push("collection:delete", value: %{id: collection.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_collection_alert"
            disabled={collection.busy}
            icon="hero-trash-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/datasets"} />

      <:portal>
        <.modal
          id="collection_modal"
          show={@live_action in [:new, :edit]}
          responsive
          backdrop={false}
          on_cancel={JS.patch(build_path(~p"/datasets", @meta))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :edit]}
            module={DataAggregatorWeb.CollectionLive.FormComponent}
            id={@collection.id || :new}
            title={@page_title}
            action={@live_action}
            collection={@collection}
            patch={build_path(~p"/datasets", @meta)}
            current_user={@current_user}
          />
        </.modal>

        <.alert
          id="confirm_collection_alert"
          size="sm"
          title={~t"Are you sure you want to delete this dataset?"m}
          confirm_button_label={~t"Yes, delete dataset"m}
        >
          <p class="mt-2 text-sm">
            <.icon name="hero-exclamation-triangle-mini" class="text-warning" />
            {~t"This will delete the dataset and all related information, such as records, encodings and images. DAGI does not support unpublishing whole datasets on GBIF. Should you need to remove a dataset from GBIF, please contact the GBIF Swiss Node"m}
            <.link href="mailto:contact@gbif.ch" class="text-primary">
              {"(contact@gbif.ch)"}
            </.link>
            {~t"for assistance."m}
          </p>
        </.alert>
      </:portal>
    </.page>
    """
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Datasets"m)
    |> assign(:collection, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Dataset"m)
    |> assign(:collection, %Collection{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Dataset"m)
    |> assign(
      :collection,
      Collection.get_by_id!(id, load: @load, actor: get_actor(socket))
    )
  end

  @impl true
  def handle_event("collection:cancel", %{"id" => id}, socket) do
    cancel_action(id, socket, load: @load)
  end

  @impl true
  def handle_event("collection:delete", %{"id" => id}, socket) do
    collection = Collection.get_by_id!(id, actor: get_actor(socket))
    :ok = Collection.destroy(collection, actor: get_actor(socket))

    {:noreply,
     socket
     |> put_flash(:info, ~t"Dataset deleted successfully"m)
     |> stream_delete(:results, collection)}
  end

  defp list_collections(params, actor, opts \\ [load: @load]) do
    opts = Keyword.put(opts, :actor, actor)
    AshPagify.validate_and_run(Collection, params, opts)
  end

  defp no_results_content(assigns) do
    ~H"""
    <%= if Collection.can_create?(@current_user) do %>
      <.empty_state
        title={~t"No datasets"m}
        description={~t"Get started by adding a new Dataset."m}
        label={~t"New datasets"m}
        icon="hero-squares-2x2"
        href={~p"/datasets/new"}
      />
    <% else %>
      <.empty_state
        title={~t"No datasets"m}
        description={~t"There are no datasets yet for your institution"m}
        icon="hero-squares-2x2"
      />
    <% end %>
    """
  end
end
