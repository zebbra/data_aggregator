defmodule Storybook.Components.Sidebar do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Header
  alias DataAggregatorWeb.Components.Sidebar

  def function, do: &Sidebar.sidebar/1
  def imports, do: [{Header, [header: 1]}]

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
            <.header title_size='text-base'>
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
