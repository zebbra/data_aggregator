defmodule Storybook.Blocks.Headings do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks
  alias DataAggregatorWeb.Components

  def layout, do: :one_column

  def function, do: &Blocks.Header.heading/1

  def imports, do: [{Components.Input, [input: 1]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title: "Hello World",
          subtitle: "I'm a header subtitle"
        }
      },
      %Variation{
        id: :with_a_subtitle,
        attributes: %{
          title: "Hello World",
          subtitle: "I'm a header subtitle"
        }
      },
      %Variation{
        id: :with_actions,
        attributes: %{
          title: "Hello World",
          subtitle: "I'm a header subtitle"
        },
        slots: [
          """
          <:actions>
            <.input type="search" name="search" value="" placeholder="Search entries" icon_start="hero-magnifying-glass" class="input-sm rounded-full" />
          </:actions>
          """
        ]
      },
      %VariationGroup{
        id: :size,
        variations:
          for size <- ~w[xs sm lg xl]a do
            %Variation{
              id: size,
              attributes: %{
                title: "Hello World",
                subtitle: "I'm a header subtitle",
                size: to_string(size)
              }
            }
          end
      }
    ]
  end
end
