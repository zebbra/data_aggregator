defmodule DataAggregatorWeb.Components.Tab do
  @moduledoc """
  Tab components that can be used to create a tabbed interface.
  """
  use Phoenix.Component

  @doc """
  Container for the tabs.
  """
  attr :class, :string, default: nil, doc: "Additional CSS classes that can be added to the tabs"

  slot :inner_block, required: true, doc: "The slot for the tab(s)"

  def tabs(assigns) do
    ~H"""
    <div role="tablist" class="tabs tabs-lifted">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Tab component.
  """
  attr :name, :string, required: true, doc: "The name for the radio input of the tab"
  attr :label, :string, required: true, doc: "The label for the tab"

  attr :class, :string,
    default: nil,
    doc: "Additional CSS classes that can be added to the tab panel"

  attr :checked, :boolean, default: false, doc: "Whether the tab is checked or not"

  slot :inner_block, required: true, doc: "The slot for the tab content"

  def tab(assigns) do
    ~H"""
    <input
      type="radio"
      name={@name}
      role="tab"
      class="tab !border-b-transparent -mx-px [--tab-border-color:var(--fallback-b3,oklch(var(--black-white)/0.1))]"
      aria-label={@label}
      checked={@checked}
    />
    <div
      role="tabpanel"
      class={["tab-content border-black-white/10 overflow-x-auto border-0 border-t", @class]}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
