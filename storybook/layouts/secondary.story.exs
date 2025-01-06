defmodule Storybook.Layouts.Secondary do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import DataAggregatorWeb.Blocks.Header, only: [page_header: 1]
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  def doc,
    do: "Sidebar navigation with sticky app-bar and main content area and an dynamic secondary sidebar on the right side."

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :show, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="home" open={@show}>
      <.page_header class="px-6 md:py-6 lg:px-8">Dashboard</.page_header>
      <div class="px-6 lg:px-8">
        <button type="button" class="btn btn-primary" phx-click="toggle">
          Toggle secondary
        </button>
      </div>
      <:secondary>
        <div class="bg-base-100 border-black-white/10 min-h-screen w-80 border-l p-4"></div>
      </:secondary>
    </.page>
    """
  end

  @impl true
  def handle_event("toggle", _, socket) do
    socket = update(socket, :show, &(!&1))

    {:noreply, socket}
  end
end
