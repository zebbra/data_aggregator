defmodule DataAggregatorWeb.Headless.Switch do
  @moduledoc """
  Switches are a pleasant interface for toggling a value between two states,
  and offer the same semantics and keyboard navigation as native checkbox elements.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Headless.Hidden
  import DataAggregatorWeb.Headless.Label
  import DataAggregatorWeb.Headless.Description

  @doc ~S"""
  Renders a switch group component with label and description. Mounts the SwitchGroupHook.

  ## Examples

  <.headless_switch_group id="switch-1__group">
    <.headless_switch id="switch-1" checked />
    <.headless_switch_label id="switch-1__label">
      Switch 1
    </.headless_switch_label>
  </.headless_switch_group>

  ## Usage

  The `HeadlessSwitchGroup` component is a wrapper for the `HeadlessSwitch`,
  `HeadlessSwitchLabel` and `HeadlessSwitchDescription` components.
  The componen ids must follow the pattern `<id>__group`, `<id>__label`, and
  `<id>__description` to work properly.
  """
  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :rest, :global
  slot :inner_block, required: true

  def headless_switch_group(assigns) do
    ~H"""
    <.dynamic_tag phx-hook="SwitchGroup" id={@id} name={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  @doc ~S"""
  Renders a switch component. Mounts the SwitchHook.

  ## Examples

  <.headless_switch id="switch-1" checked />
  """

  attr :id, :string, required: true
  attr :as, :string, default: "button"
  attr :checked, :boolean, default: false
  attr :value, :string, default: "on"
  attr :form, :string, default: nil, doc: "The form the switch belongs to."
  attr :name, :string, default: nil, doc: "The name of the switch."
  attr :class, :string, default: nil
  attr :slot_class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def headless_switch(assigns) do
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
    <span aria-hidden="true" class={@slot_class} />
    """
  end

  @doc ~S"""
  Renders a switch label component. Mounts the SwitchLabelHook.

  ## Examples

  <.headless_switch_label id="switch-1__label">
    Switch 1
  </.headless_switch_label>

  ## Usage

  The componen id must follow the pattern `<id>__label` to work properly.
  """

  attr :id, :string, required: true
  attr :passive, :boolean, default: false, doc: "Passive labels are not clickable."
  attr :as, :string, default: "label"
  attr :rest, :global
  slot :inner_block, required: true

  def headless_switch_label(assigns) do
    ~H"""
    <.label phx-hook="Label" id={@id} passive={@passive} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.label>
    """
  end

  @doc ~S"""
  Renders a switch description component. Mounts the SwitchDescriptionHook.

  ## Examples

  <.headless_switch_description id="switch-1__description">
    Switch 1 description
  </.headless_switch_description>

  ## Usage

  The componen id must follow the pattern `<id>__description` to work properly.
  """

  attr :id, :string, required: true
  attr :as, :string, default: "p"
  attr :rest, :global
  slot :inner_block, required: true

  def headless_switch_description(assigns) do
    ~H"""
    <.description phx-hook="Description" id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.description>
    """
  end
end
