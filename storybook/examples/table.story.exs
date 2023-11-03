defmodule Storybook.Examples.Table do
  use PhoenixStorybook.Story, :example

  import Elixir.DataAggregatorWeb.CoreComponents, only: [table: 1]

  def doc, do: "This is a basic table example."

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(
        :results,
        [
          %{id: 1, username: "jose"},
          %{id: 2, username: "chris"}
        ],
        reset: true,
        at: 0,
        limit: 0
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.table id="users" rows={@streams.results}>
        <:col :let={{_id, user}} label="ID" field="id">
          <%= user.id %>
        </:col>
        <:col :let={{_id, user}} label="Username" field="username">
          <%= user.username %>
        </:col>
      </.table>
    </div>
    """
  end
end
