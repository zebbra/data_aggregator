defmodule Storybook.Blocks.Header do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Blocks

  def function, do: &Blocks.Header.header/1

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          "Hello World"
        ]
      },
      %Variation{
        id: :with_a_subtitle,
        slots: [
          "Hello World",
          "<:subtitle>I'm a header subtitle</:subtitle>"
        ]
      },
      %Variation{
        id: :with_actions,
        slots: [
          "Hello World",
          "<:subtitle>I'm a header subtitle</:subtitle>",
          """
          <:actions>
            <button type="button" class="btn btn-neutral">Link</button>
          </:actions>
          """
        ]
      }
    ]
  end
end
