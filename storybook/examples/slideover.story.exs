defmodule Storybook.Examples.Slideover do
  use PhoenixStorybook.Story, :example

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.HeadlessComponents, only: [slideover: 1]
  import DataAggregatorWeb.CoreComponents

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
    <.button id="record-slideover__button" phx-click="toggle">Show</.button>
    <aside
      :if={@show}
      class="xl:block xl:fixed xl:bottom-0 xl:right-0 xl:top-16 xl:w-96 xl:overflow-y-auto dark:bg-gray-900 hidden"
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
      <div class="flex flex-col h-full">
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
        <.header dialog_header_id={@slideover_id} class="sticky top-0">
          Record ID
          <:subtitle>
            This is a record from your database.
          </:subtitle>
        </.header>
      </:header>
      <.list>
        <:item title="ID">1234</:item>
        <:item title="Material Entity ID">Stone</:item>
        <:item title="Scientific Name">Stone 1</:item>
      </.list>
      <:footer>
        <.button phx-click="toggle" variant="secondary" class="inline-flex mr-2">
          <span>Close</span>
        </.button>
        <.styled_link>
          <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
          <span>Edit Record</span>
        </.styled_link>
      </:footer>
    </.sidebar>
    """
  end
end
