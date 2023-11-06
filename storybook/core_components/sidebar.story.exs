defmodule Storybook.CoreComponents.Sidebar do
  use PhoenixStorybook.Story, :component

  alias Elixir.DataAggregatorWeb.CoreComponents

  def function, do: &CoreComponents.sidebar/1
  def imports, do: [{CoreComponents, [header: 1]}]

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
            <.header>
              Header
              <:subtitle>
                I'm a header subtitle
              </:subtitle>
            </.header>
          </:header>",
          "<:footer>Footer</:footer>"
        ]
      }
    ]
  end
end
