defmodule Storybook.Layouts.Primary do
  use PhoenixStorybook.Story, :example

  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]
  import DataAggregatorWeb.Blocks.Header, only: [header: 1]

  def doc, do: "Sidebar navigation with sticky app-bar and main content area."

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="records">
      <.header>Records</.header>
    </.page>
    """
  end
end
