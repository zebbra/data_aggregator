defmodule DataAggregatorWeb.ImportLive.Show do
  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.ImportLive.Components

  alias DataAggregator.PubSub
  alias DataAggregator.Records.Import
  alias Phoenix.LiveView.Socket

  require Logger

  @load [:collection, :progress, attachment: [:url, :filename, :byte_size]]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket =
      socket
      |> assign_import(id)
      |> subscribe_for_updates()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  defp subscribe_for_updates(socket) do
    with true <- connected?(socket),
         %Socket{assigns: %{import: import}} <- socket,
         %Import{id: id} <- import,
         topic <- "import:updated:#{id}" do
      PubSub.subscribe(topic)
      socket
    else
      false ->
        socket

      other ->
        Logger.warning("Unable to subscribe for import updates: #{other}")
        socket
    end
  end

  defp assign_import(socket, id) do
    {:ok, import} = Import.get_by_id(id, load: @load)
    assign(socket, :import, import)
  end

  defp update_import(socket) do
    %Socket{assigns: %{import: %Import{id: id}}} = socket
    assign_import(socket, id)
  end

  defp apply_action(socket, :show, _params) do
    assign(socket, :page_title, ~t"Show Import"m)
  end

  defp apply_action(socket, action, _params) do
    assign(socket, :page_title, "Action #{action}")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:imports} environment={@environment} sidebar_nav={@sidebar_nav}>
      <div class="sticky top-16">
        <.import_header import={@import} action={@live_action} />
        <.import_steps import={@import} active={@live_action} />
      </div>
      <.render_action import={@import} action={@live_action} />
    </.page>
    """
  end

  attr :import, :map, required: true
  attr :action, :atom, required: true

  def render_action(%{action: :mappings} = assigns) do
    ~H"""
    <.import_mapping_form import={@import} />
    """
  end

  def render_action(%{action: :show} = assigns) do
    ~H"""
    <.list>
      <:item title="State"><.import_state_badge state={@import.state} /></:item>
      <:item title="Attachment"><.import_attachment import={@import} /></:item>
      <:item title="Created at"><%= format_datetime(@import.inserted_at) %></:item>
      <:item title="Updated at"><%= format_datetime(@import.updated_at) %></:item>
      <:item title="Imported at"><%= format_datetime(@import.imported_at) %></:item>
    </.list>
    """
  end

  def render_action(%{action: :confirmation} = assigns) do
    ~H"""
    <div class="p-4" phx-click="">
      <.button phx-click="import:run">Import!</.button>
    </div>
    """
  end

  def render_action(assigns) do
    ~H"""
    Action <%= @action %> not implemented!
    """
  end

  @impl true
  def handle_info({_topic, _event, _notification}, socket) do
    socket = update_import(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("import:run", _params, socket) do
    %Socket{assigns: %{import: import}} = socket

    socket =
      case Import.enqueue(import) do
        {:ok, import} ->
          assign(socket, :import, import)

        # |> put_flash(:info, ~t"Import started ..."m)

        {:error, _error} ->
          put_flash(socket, :error, ~t"Import could not be started"m)
      end

    {:noreply, socket}
  end
end
