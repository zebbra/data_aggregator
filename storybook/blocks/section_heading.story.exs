defmodule Storybook.Blocks.SectionHeading do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks
  alias DataAggregatorWeb.Components

  def layout, do: :one_column

  def function, do: &Blocks.Header.section_heading/1

  def imports, do: [{Components.Input, [input: 1]}]

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          """
          Hello World
          """
        ]
      },
      %Variation{
        id: :with_a_subtitle,
        slots: [
          """
          Hello World
          <:subtitle>
            I'm a header subtitle
          </:subtitle>
          """
        ]
      },
      %Variation{
        id: :with_attributes,
        attributes: %{
          text: "Hello World",
          description: "I'm a header subtitle"
        }
      },
      %Variation{
        id: :with_actions,
        slots: [
          """
          Hello World
          <:subtitle>
            I'm a header subtitle
          </:subtitle>
          <:actions>
            <.input type="search" name="search" value="" placeholder="Search entries" icon_start="hero-magnifying-glass" class="input-sm rounded-full" />
          </:actions>
          """
        ]
      },
      %VariationGroup{
        id: :size,
        variations:
          for size <- ~w[sm md lg xl]a do
            %Variation{
              id: size,
              attributes: %{
                size: to_string(size)
              },
              slots: [
                """
                Hello World
                <:subtitle>
                  I'm a header subtitle
                </:subtitle>
                """
              ]
            }
          end
      }
    ]
  end
end
