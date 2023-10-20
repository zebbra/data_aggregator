defmodule DataAggregatorWeb.CollectionLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.Collection

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = Collection.get_by_id!(id, load: [import_files: [:data]])
    import_file = collection.import_files |> List.last()

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:import_file, import_file)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, ~t"Show Collection"m)
  end

  defp apply_action(socket, :import, _params) do
    socket
    |> assign(:page_title, ~t"Import File"m)
  end

  @impl true
  def handle_info(
        {DataAggregatorWeb.CollectionLive.FormComponent, {:saved, collection}},
        socket
      ) do
    {:noreply, assign(socket, :collection, collection)}
  end

  def render(assigns) do
    ~H"""
    <main>
      <.header class="sticky top-16">
        <%= @collection.name %>

        <:actions>
          <.link navigate={~p"/collections/#{@collection}/import"} class="focus-visible:outline-none">
            <.button class="inline-flex">
              <.icon name="hero-plus-circle-mini" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
              <span class="sm:inline-block hidden"><%= ~t"Import File"m %></span>
            </.button>
          </.link>
        </:actions>
      </.header>

      <div :if={@import_file}>
        <.table id="columns" rows={@import_file.data |> Explorer.DataFrame.dtypes()}>
          <:col :let={{name, _}} label="Name"><%= name %></:col>
          <:col :let={{_, type}} label="Type"><%= type %></:col>
        </.table>
      </div>

      <.modal
        :if={@live_action == :import}
        id="collection-modal"
        on_cancel={JS.patch(~p"/collections/#{@collection}")}
      >
        <.live_component
          module={DataAggregatorWeb.CollectionLive.ImportFormComponent}
          id={@collection.id}
          icon="hero-plus-circle-mini"
          title={@page_title}
          action={:new}
          collection={@collection}
          patch={~p"/collections/#{@collection}"}
        />
      </.modal>
    </main>
    """
  end
end
