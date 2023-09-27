defmodule DataAggregatorWeb.Headless.Switch do
  @moduledoc """
  Switches are a pleasant interface for toggling a value between two states,
  and offer the same semantics and keyboard navigation as native checkbox elements.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Headless.Hidden
  import DataAggregatorWeb.Headless.Label
  import DataAggregatorWeb.Headless.Description

  @doc """
  Renders a switch group component with label and description.

  ## Examples

      <.switch_group id="switch-2__group" class="flex items-center">
        <.switch id="switch-2" checked />
        <.switch_label id="switch-2__label" class="ml-3 text-sm">
          <span class="font-medium text-gray-900">Annual billing</span>
        </.switch_label>
      </.switch_group>

  ## Usage

  The `SwitchGroup` component is a wrapper for the `Switch`, `SwitchLabel` and
  `SwitchDescription` components.
  The componen ids must follow the pattern `<id>__group`, `<id>__label`, and
  `<id>__description` to work properly.
  """
  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :rest, :global
  slot :inner_block, required: true

  def switch_group(assigns) do
    ~H"""
    <.dynamic_tag phx-hook="SwitchGroup" id={@id} name={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "button"
  attr :checked, :boolean, default: false
  attr :value, :string, default: "on"
  attr :form, :string, default: nil
  attr :name, :string, default: nil

  attr :class, :string,
    default:
      "bg-gray-200 aria-checked:bg-indigo-600 w-11 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 relative inline-flex flex-shrink-0 h-6 transition-colors duration-200 ease-in-out border-2 border-transparent rounded-full cursor-pointer"

  attr :rest, :global
  slot :inner_block

  def switch(assigns) do
    ~H"""
    <%= if @name != nil && @checked != nil do %>
      <.hidden
        features={hidden_features_none()}
        type="checkbox"
        hidden={true}
        readonly={true}
        checked={@checked}
        form={@form}
        name={@name}
        value={@value}
      />
    <% end %>
    <.dynamic_tag
      phx-hook="Switch"
      id={@id}
      name={@as}
      role="switch"
      type={(@as == "button" && "button") || @rest.type}
      tabindex="0"
      aria-checked={@checked}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) || default_switch(assigns) %>
    </.dynamic_tag>
    """
  end

  defp default_switch(assigns) do
    ~H"""
    <span class="sr-only">Toggle</span>
    <span
      aria-hidden="true"
      class="ring-0 group-[.is-checked]/checked:translate-x-5 inline-block w-5 h-5 transition duration-200 ease-in-out transform translate-x-0 bg-white rounded-full shadow pointer-events-none"
    />
    """
  end

  attr :id, :string, required: true
  attr :passive, :boolean, default: false
  attr :as, :string, default: "label"
  attr :rest, :global
  slot :inner_block, required: true

  def switch_label(assigns) do
    ~H"""
    <.label phx-hook="Label" id={@id} passive={@passive} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.label>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "p"
  attr :rest, :global
  slot :inner_block, required: true

  def switch_description(assigns) do
    ~H"""
    <.description phx-hook="Description" id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.description>
    """
  end
end
