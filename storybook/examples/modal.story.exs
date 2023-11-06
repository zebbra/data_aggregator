defmodule Storybook.Examples.Modal do
  use PhoenixStorybook.Story, :example

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.HeadlessComponents, only: [modal: 1]
  import DataAggregatorWeb.CoreComponents, only: [button: 1, header: 1]

  def doc, do: "This is a basic modal example."

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
    <div>
      <.button id="modal__button" phx-click={JS.push("toggle")}>
        Open Modal
      </.button>
      <.modal :if={@show} id="modal" on_cancel={JS.push("toggle")} on_confirm={JS.push("toggle")}>
        <div class="w-80">
          <.header>
            Header
            <:subtitle>With a subtitle</:subtitle>
          </.header>
        </div>
        <:cancel>Close</:cancel>
        <:confirm>Confirm</:confirm>
      </.modal>
    </div>
    """
  end
end
