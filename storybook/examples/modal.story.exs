defmodule Storybook.Examples.Modal do
  @moduledoc false
  use PhoenixStorybook.Story, :example
  use DataAggregatorWeb.Components

  alias Phoenix.LiveView.JS

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
      <.button id="modal__button" phx-click={JS.push("toggle")} label="Open Modal" />
      <.modal :if={@show} id="modal" on_cancel={JS.push("toggle")} on_confirm={JS.push("toggle")}>
        <.modal_header
          modal_id="modal"
          title="Header"
          description="With a subtitle"
          icon="hero-check-circle-mini"
        />
        <:cancel>Close</:cancel>
        <:confirm>Confirm</:confirm>
      </.modal>
    </div>
    """
  end
end
