defmodule Storybook.Components.Breadcrumbs do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Breadcrumbs.breadcrumbs/1

  def variations do
    [
      %Variation{
        id: :with_one_item,
        attributes: %{
          items: [%{label: "Home", link: "#"}]
        }
      },
      %Variation{
        id: :with_two_items,
        attributes: %{
          items: [%{label: "Home", link: "#"}, %{label: "Documents", link: "#"}]
        }
      },
      %Variation{
        id: :with_three_items,
        attributes: %{
          items: [
            %{label: "Home", link: "#"},
            %{label: "Documents", link: "#"},
            %{label: "Details", link: "#"}
          ]
        }
      }
    ]
  end
end
