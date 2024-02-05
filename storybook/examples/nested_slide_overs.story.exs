defmodule Storybook.Examples.NestedSlideOvers do
  @moduledoc false
  use PhoenixStorybook.Story, :example
  use DataAggregatorWeb.Components

  alias Phoenix.LiveView.JS

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
          <.button id="drawer__button" phx-click="toggle_drawer" label="Drawer" />
        </:actions>
      </.header>
      <div class="p-4 dark:text-white sm:px-6 lg:px-8">
        <div>Drawer: <%= @drawer %></div>
        <div>Level: <%= @level_1 %></div>
        <div>Modal: <%= @modal %></div>
        <div>Other Modal: <%= @other_modal %></div>
      </div>
      <:portal>
        <.slideover
          :if={@drawer}
          id="drawer"
          responsive="lg:flex"
          show={false}
          class="hidden relative z-50"
          close_button={false}
          on_cancel={JS.push("toggle_drawer")}
        >
          <div class="flex h-full flex-col">
            <.sidebar>
              <:header>
                <.sidebar_header sidebar_id="drawer" class="sticky top-0">
                  Drawer
                  <:subtitle>
                    This is the base drawer
                  </:subtitle>
                </.sidebar_header>
              </:header>
              <.list :for={x <- 1..4}>
                <:item title="ID">Item <%= x %></:item>
              </.list>
              <:footer>
                <.button
                  color="secondary"
                  class="inline-flex mr-2"
                  phx-click="toggle_drawer"
                  label="Close"
                />
                <.button id="level_1__button" phx-click="toggle_level_1" label="Level 1" />
                <.button
                  class="ml-2"
                  id="other-modal__button"
                  phx-click="toggle_other_modal"
                  label="Other Modal"
                />
              </:footer>
            </.sidebar>
          </div>

          <.slideover
            :if={@level_1}
            id="level_1"
            responsive="lg:flex"
            show={false}
            parent_id="drawer"
            backdrop={false}
            close_button={false}
            on_cancel={JS.push("toggle_level_1")}
          >
            <div class="flex h-full flex-col">
              <.sidebar>
                <:header>
                  <.sidebar_header sidebar_id="level_1" class="sticky top-0">
                    Level 1
                    <:subtitle>
                      This is the second level drawer.
                    </:subtitle>
                  </.sidebar_header>
                </:header>
                <.list :for={x <- 1..20}>
                  <:item title="ID">Item <%= x %></:item>
                </.list>
                <:footer>
                  <.button color="secondary" class="mr-2" phx-click="toggle_level_1" label="Close" />
                  <.button id="modal__button" phx-click="toggle_modal" label="Modal" />
                </:footer>
              </.sidebar>
            </div>
            <.modal
              :if={@modal}
              id="modal"
              responsive="lg:flex"
              show={false}
              parent_id="level_1"
              backdrop={false}
              on_cancel={JS.push("toggle_modal")}
            >
              <.modal_header
                modal_id="modal"
                title="Modal"
                description="This is a modal inside a drawer"
              />
              <:cancel>
                Close
              </:cancel>
            </.modal>
          </.slideover>
        </.slideover>
      </:portal>
      <:portal>
        <.modal id="other-modal" show={@other_modal} on_cancel={JS.push("toggle_other_modal")}>
          <.modal_header modal_id="other-modal" title="Modal" description="This is an other modal" />
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
    <div class="no-scrollbar isolate h-screen overflow-y-auto dark:bg-gray-900">
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
