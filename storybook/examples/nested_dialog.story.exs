defmodule Storybook.Examples.NestedDialog do
  use PhoenixStorybook.Story, :example
  use DataAggregatorWeb.ViewportHelpers

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.HeadlessComponents, only: [slideover: 1, modal: 1]
  import DataAggregatorWeb.CoreComponents

  def doc,
    do: """
    <h1>
    This is an advanced dialog example to show how to nest dialogs.
    </h1>
    <section>Features:</section>
    <ul>
      <li>- Handle display state either with an `:if` directive or with the `show` attribute</li>
      <li>- Define responsive breakpoints to hide / show dialogs</li>
      <li>- Escape listeners are captured in child dialogs</li>
      <li>- Body is properly marked as inert and can't be interacted with during an open dialog</li>
    </ul>
    """

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, drawer: false, level_1: false, modal: false, other_modal: false)}
  end

  @impl true
  def handle_event("toggle_modal", _, socket) do
    socket = update(socket, :modal, &(!&1))
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_other_modal", _, socket) do
    socket =
      socket
      |> update(:other_modal, &(!&1))
      |> assign(:drawer, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_drawer", _, socket) do
    socket = update(socket, :drawer, &(!&1))
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_level_1", _, socket) do
    socket = update(socket, :level_1, &(!&1))
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.portal_wrapper>
      <.header>
        Dashboard
        <:actions>
          <.button id="drawer__button" phx-click="toggle_drawer">
            Drawer
          </.button>
        </:actions>
      </.header>
      <div class="dark:text-white sm:px-6 lg:px-8 p-4">
        <div>Drawer: <%= @drawer %></div>
        <div>Level: <%= @level_1 %></div>
        <div>Modal: <%= @modal %></div>
        <div>Other Modal: <%= @other_modal %></div>
      </div>
      <:portal>
        <.slideover
          show={@drawer and display_size_lg(@viewport_width)}
          id="drawer"
          class="relative z-50 hidden"
          close_button={false}
          on_cancel={JS.push("toggle_drawer")}
        >
          <div class="flex flex-col h-full">
            <.sidebar>
              <:header>
                <.header dialog_header_id="drawer" class="sticky top-0">
                  Drawer
                  <:subtitle>
                    This is the base drawer
                  </:subtitle>
                </.header>
              </:header>
              <.list :for={x <- 1..4}>
                <:item title="ID">Item <%= x %></:item>
              </.list>
              <:footer>
                <.button variant="secondary" class="inline-flex mr-2" phx-click="toggle_drawer">
                  <span>Close</span>
                </.button>
                <.button id="level_1__button" phx-click="toggle_level_1">Level 1</.button>
                <.button class="ml-2" id="other-modal__button" phx-click="toggle_other_modal">
                  Other Modal
                </.button>
              </:footer>
            </.sidebar>
          </div>

          <.slideover
            show={@level_1 and display_size_lg(@viewport_width)}
            id="level_1"
            parent_id="drawer"
            backdrop={false}
            close_button={false}
            on_cancel={JS.push("toggle_level_1")}
          >
            <div class="flex flex-col h-full">
              <.sidebar>
                <:header>
                  <.header dialog_header_id="level_1" class="sticky top-0">
                    Level 1
                    <:subtitle>
                      This is the second level drawer.
                    </:subtitle>
                  </.header>
                </:header>
                <.list :for={x <- 1..20}>
                  <:item title="ID">Item <%= x %></:item>
                </.list>
                <:footer>
                  <.button variant="secondary" class="inline-flex mr-2" phx-click="toggle_level_1">
                    <span>Close</span>
                  </.button>
                  <.button id="modal__button" phx-click="toggle_modal">Modal</.button>
                </:footer>
              </.sidebar>
            </div>
            <.modal
              show={@modal and display_size_lg(@viewport_width)}
              id="modal"
              parent_id="level_1"
              backdrop={false}
              on_cancel={JS.push("toggle_modal")}
            >
              <.header dialog_header_id="modal">
                Modal
                <:subtitle>
                  This is a modal inside a drawer.
                </:subtitle>
              </.header>
              <:cancel>
                Close
              </:cancel>
            </.modal>
          </.slideover>
        </.slideover>
      </:portal>
      <:portal>
        <.modal id="other-modal" show={@other_modal} on_cancel={JS.push("toggle_other_modal")}>
          <.header dialog_header_id="other-modal">
            Modal
            <:subtitle>
              This is an other modal.
            </:subtitle>
          </.header>
          <:cancel>
            Close
          </:cancel>
        </.modal>
      </:portal>
    </.portal_wrapper>
    """
  end

  slot :inner_block, required: true
  slot :portal

  def portal_wrapper(assigns) do
    ~H"""
    <div
      id="portal-wrapper"
      phx-hook="ViewportResize"
      class="dark:bg-gray-900 no-scrollbar isolate h-screen overflow-y-auto"
    >
      <main>
        <%= render_slot(@inner_block) %>
      </main>
      <div class="isolate" id="headless-portal-root">
        <%= for portal <- @portal do %>
          <%= render_slot(portal) %>
        <% end %>
      </div>
    </div>
    """
  end
end
