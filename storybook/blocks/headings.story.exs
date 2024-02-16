defmodule Storybook.Blocks.Headings do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Blocks

  def layout, do: :one_column

  def function, do: &Blocks.Header.heading/1

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
