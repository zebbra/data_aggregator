defmodule Storybook.Blocks.Slideover do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks

  def layout, do: :one_column

  def function, do: &Blocks.Slideover.slideover/1

  def imports, do: [{Blocks.Header, [header: 1]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title: "Slideover title",
          open: true,
          compact: true
        },
        slots: [
          """
          <p class="px-6 lg:px-8">
            This is the inner block of the slideover.
          </p>
          """
        ]
      },
      %Variation{
        id: :with_footer,
        attributes: %{
          title: "Slideover title",
          open: true,
          compact: true
        },
        slots: [
          """
          <p class="px-6 lg:px-8">
            This is the inner block of the slideover.
          </p>
          <:footer>
            <button type="button" class="btn btn-primary max-sm:btn-sm">Link</button>
          </:footer>
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
                title: "Slideover title",
                open: true,
                compact: true,
                size: to_string(size)
              },
              slots: [
                """
                <p class="px-6 lg:px-8">
                  This is the inner block of the slideover.
                </p>
                <:footer>
                  <button type="button" class="btn btn-primary max-sm:btn-sm">Link</button>
                </:footer>
                """
              ]
            }
          end
      }
    ]
  end
end
