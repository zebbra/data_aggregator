defmodule DataAggregatorWeb.CollectionLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Collection

  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  @impl true
  def mount(_params, _session, socket) do
    results = Collection.read!(load: [:records_count, :digitizing_progress])
    socket = stream(socket, :results, results)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections">
      <div class="grid gap-y-4">
        <.header>
          <%= ~t"Collections"m %>
          <:actions>
            <.link patch={~p"/collections/new"} class="btn btn-neutral max-sm:btn-sm">
              <.icon name="hero-plus-mini" class="max-sm:hidden" />
              <%= ~t"New collection"m %>
            </.link>
          </:actions>
        </.header>

        <div class="no-scrollbar overflow-x-auto pb-4">
          <.table id="collections-table" rows={@streams.results}>
            <:col :let={{_id, collection}} label={~t"Name"m}>
              <.link navigate={~p"/collections/#{collection.id}"} class="link link-primary">
                <%= collection.name %>
              </.link>
            </:col>

            <:col :let={{_id, collection}} label={~t"Code"m}>
              <%= collection.code %>
            </:col>

            <:col :let={{_id, collection}} label={~t"Institution"m}>
              <%= collection.institution %>
            </:col>

            <:col :let={{_id, collection}} label={~t"Progress"m} class="text-right">
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

            <:col :let={{_id, collection}} label={~t"Records count / est."m}>
              <%= inspect(collection.records_count) %> / <%= collection.items_to_digitize %>
            </:col>

            <:col :let={{_id, collection}} label={~t"Updated At"m}>
              <%= format_datetime(collection.updated_at, format: :short) %>
            </:col>

            <:action :let={{_id, collection}} class="-mx-3 -my-1.5 sm:-mx-2.5">
              <.table_actions id={"collection-#{collection.id}"}>
                <li>
                  <.link
                    patch={~p"/collections/#{collection.id}"}
                    class="hover:bg-primary hover:text-primary-content"
                  >
                    <%= ~t"View"m %>
                  </.link>
                </li>
                <li>
                  <.link
                    patch={~p"/collections/#{collection}/edit"}
                    class="hover:bg-primary hover:text-primary-content"
                  >
                    <%= ~t"Edit"m %>
                  </.link>
                </li>
                <li>
                  <.link
                    phx-click={JS.push("delete", value: %{id: collection.id})}
                    class="hover:bg-primary hover:text-primary-content"
                    data-confirm={~t"Are you sure?"m}
                  >
                    <%= ~t"Delete"m %>
                  </.link>
                </li>
              </.table_actions>
            </:action>
          </.table>
        </div>
      </div>

      <:portal>
        <.modal
          id="collection_modal"
          show={@live_action in [:new, :edit]}
          responsive
          backdrop={false}
          on_cancel={JS.patch(~p"/collections")}
        >
          <.live_component
            :if={@live_action in [:new, :edit]}
            module={DataAggregatorWeb.CollectionLive.FormComponent}
            id={@collection.id || :new}
            title={@page_title}
            action={@live_action}
            collection={@collection}
            patch={~p"/collections"}
          />
        </.modal>
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
      Collection.get_by_id!(id, load: [:records_count, :digitizing_progress])
    )
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.CollectionLive.FormComponent, {:saved, collection}},
        socket
      ) do
    {:noreply,
     stream_insert(
       socket,
       :results,
       Collection.get_by_id!(collection.id, load: [:records_count, :digitizing_progress])
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    collection = Collection.get_by_id!(id)
    :ok = Collection.destroy(collection)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Collection deleted successfully"m)
     |> stream_delete(:results, collection)}
  end
end
