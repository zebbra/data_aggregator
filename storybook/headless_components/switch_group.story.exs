defmodule Storybook.HeadlessComponents.SwitchGroup do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.HeadlessComponents

  def function, do: &HeadlessComponents.switch/1

  def imports do
    [{HeadlessComponents, [switch_group: 1, switch_label: 1, switch_description: 1]}]
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
      <.lsb-variation/>
      <HeadlessComponents.switch_description
        id=":variation_id__description"
        as="span"
        class="text-sm leading-5 text-gray-500"
      >
        Description
      </HeadlessComponents.switch_description>
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
