defmodule Storybook.HeadlessComponents.SwitchGroup do
  use PhoenixStorybook.Story, :component

  alias Elixir.DataAggregatorWeb.HeadlessComponents

  def function, do: &HeadlessComponents.switch/1

  def imports do
    [{HeadlessComponents, [switch_group: 1, switch_label: 1]}]
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
