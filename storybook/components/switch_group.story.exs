defmodule Storybook.Components.SwitchGroup do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Switch

  def function, do: &Switch.switch/1

  def imports do
    [{Switch, [switch_group: 1, switch_label: 1, switch_description: 1]}]
  end

  def template do
    """
    <.switch_group id=":variation_id__group" class="flex items-center justify-between space-x-2">
      <span class="flex flex-col flex-grow">
        <.switch_label
          id=":variation_id__label"
          as="span"
          class="text-sm font-medium leading-6 text-gray-900"
        >
          Available to hire
        </.switch_label>
      </span>
      <.psb-variation/>
      <Switch.switch_description
        id=":variation_id__description"
        as="span"
        class="text-sm leading-5 text-gray-500"
      >
        Description
      </Switch.switch_description>
    </.switch_group>
    """
  end

  def variations do
    [
      %Variation{
        id: :switch_group
      }
    ]
  end
end
