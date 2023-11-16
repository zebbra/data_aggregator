defmodule Storybook.Examples.Slideover do
  use PhoenixStorybook.Story, :example
  use DataAggregatorWeb.Components

  alias Phoenix.LiveView.JS

  def doc,
    do:
      "This an advanced slideover example with fixed sidebar on xl and responsive slideover on < xl."

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, show: false)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle", _, socket) do
    {:noreply, update(socket, :show, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.button id="record-slideover__button" phx-click="toggle" label="Show" />
    <aside
      :if={@show}
      class="hidden dark:bg-gray-900 xl:fixed xl:top-16 xl:right-0 xl:bottom-0 xl:block xl:w-96 xl:overflow-y-auto"
    >
      <.preview_content />
    </aside>

    <.slideover
      :if={@show}
      id="record-slideover"
      responsive="xl:hidden"
      show={false}
      on_cancel={JS.push("toggle")}
    >
      <div class="flex h-full flex-col">
        <.preview_content slideover_id="record-slideover" />
      </div>
    </.slideover>
    """
  end

  attr :slideover_id, :string, default: nil

  defp preview_content(assigns) do
    ~H"""
    <.sidebar>
      <:header>
        <.sidebar_header sidebar_id={@slideover_id} class="sticky top-0">
          Record ID
          <:subtitle>
            This is a record from your database.
          </:subtitle>
        </.sidebar_header>
      </:header>
      <.list>
        <:item title="ID">1234</:item>
        <:item title="Material Entity ID">Stone</:item>
        <:item title="Scientific Name">Stone 1</:item>
      </.list>
      <:footer>
        <.button phx-click="toggle" color="secondary" label="Close" class="mr-2" />
        <.button icon="hero-pencil-square-mini" label="Edit Record" />
      </:footer>
    </.sidebar>
    """
  end
end
