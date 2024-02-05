defmodule Storybook.Components.Switch do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DataAggregatorWeb.Components.Switch.switch/1

  def variations do
    [
      %Variation{
        id: :default
      },
      %Variation{
        id: :form,
        attributes: %{
          name: "story[switch]"
        }
      },
      %Variation{
        id: :slot,
        slots: [
          """
          <span class="sr-only">Use setting</span>
          <span class="group-aria-checked:translate-x-5 ring-0 relative inline-block w-5 h-5 transition duration-200 ease-in-out transform translate-x-0 bg-white rounded-full shadow pointer-events-none" />
          """
        ]
      }
    ]
  end
end
