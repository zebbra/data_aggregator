defmodule Storybook.Components.Sidebar do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Sidebar

  def function, do: &Sidebar.sidebar/1
  def imports, do: [{Sidebar, [sidebar_header: 1]}]

  def template do
    """
    <aside class="w-full h-screen">
      <.lsb-variation/>
    </aside>
    """
  end

  def variations do
    [
      %Variation{
        id: :sidebar,
        slots: [
          "<:header>
            <.sidebar_header>
              Header
              <:subtitle>
                I'm a header subtitle
              </:subtitle>
            </.sidebar_header>
          </:header>",
          "<:footer>Footer</:footer>"
        ]
      }
    ]
  end
end
