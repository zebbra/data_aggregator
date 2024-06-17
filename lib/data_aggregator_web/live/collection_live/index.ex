defmodule DataAggregatorWeb.CollectionLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.CollectionLive.Subscriptions

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
    case list_collections(params) do
      {:ok, {collections, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, collections, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <.page_header class="px-6 pb-4 pt-1 lg:px-8 md:py-6">
        <%= ~t"Collections"m %>
        <:actions>
          <.link patch={build_path(~p"/collections/new", @meta)} class="btn btn-primary max-sm:btn-sm">
            <.icon name="hero-squares-2x2" class="max-sm:size-4" />
            <span class="max-sm:hidden"><%= ~t"New collection"m %></span>
            <span class="sm:hidden"><%= ~t"Add"m %></span>
          </.link>
        </:actions>
      </.page_header>

      <.table
        opts={[
          container_attrs: [
            class: "no-scrollbar overflow-x-auto pb-4"
          ],
          no_results_content: no_results_content(%{collection: @collection})
        ]}
        path={~p"/collections"}
        items={@streams.results}
        meta={@meta}
      >
        <:col :let={{_id, collection}} field={:name} label={~t"Name"m}>
          <.link
            navigate={~p"/collections/#{collection}/records"}
            class="link link-primary font-semibold link-hover"
          >
            <%= collection.name %>
          </.link>
        </:col>
        <:col :let={{_id, collection}} field={:code} label={~t"Code"m}>
          <%= collection.code %>
        </:col>
        <:col :let={{_id, collection}} label={~t"Institution"m}>
          <%= collection.institution %>
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
              class="progress progress-primary min-w-32"
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
          <%= inspect(collection.records_count) %> / <%= collection.items_to_digitize %>
        </:col>
        <:col :let={{_id, collection}} field={:updated_at} label={~t"Updated At"m} class="text-right">
          <%= format_datetime(collection.updated_at, format: :short) %>
        </:col>

        <:action
          :let={{_id, collection}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.table_action_button
              patch={build_path(~p"/collections/#{collection}/edit", @meta)}
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
      <.pagination meta={@meta} path={~p"/collections"} />

      <:portal>
        <.modal
          id="collection_modal"
          show={@live_action in [:new, :edit]}
          responsive
          backdrop={false}
          on_cancel={JS.patch(build_path(~p"/collections", @meta))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :edit]}
            module={DataAggregatorWeb.CollectionLive.FormComponent}
            id={@collection.id || :new}
            title={@page_title}
            action={@live_action}
            collection={@collection}
            patch={build_path(~p"/collections", @meta)}
          />
        </.modal>

        <.alert
          id="confirm_collection_alert"
          size="sm"
          title={~t"Are you sure?"m}
          label={~t"Yes, delete collection"m}
        />
      </:portal>
    </.page>
    """
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Collections"m)
    |> assign(:collection, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Collection"m)
    |> assign(:collection, %Collection{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit Collection"m)
    |> assign(
      :collection,
      Collection.get_by_id!(id, load: @load)
    )
  end

  @impl true
  def handle_event("collection:delete", %{"id" => id}, socket) do
    collection = Collection.get_by_id!(id)
    :ok = Collection.destroy(collection)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Collection deleted successfully"m)
     |> stream_delete(:results, collection)}
  end

  defp list_collections(params, opts \\ [load: @load]) do
    Pagify.validate_and_run(Collection, params, opts)
  end

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No collections"m}
      description={~t"Get started by adding a new collection."m}
      label={~t"New collection"m}
      icon="hero-squares-2x2"
      href={~p"/collections/new"}
    />
    """
  end
end
