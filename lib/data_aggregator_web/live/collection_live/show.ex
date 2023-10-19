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

    socket =  socket
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
    |> assign(:page_title, ~t"Import Collection"m)
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
     <.link navigate={~p"/collections/#{@collection}/import"}>Import</.link>

    <div :if={@import_file}>
      <.table id="columns" rows={@import_file.data |> Explorer.DataFrame.dtypes()}>
        <:col :let={{name, _}}><%= name %></:col>
        <:col :let={{_, type}}><%= type %></:col>
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
    """
  end
end
