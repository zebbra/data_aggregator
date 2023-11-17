defmodule DataAggregatorWeb.Components.Switch do
  @moduledoc """
  Renders a switch with label and description with tailwindui style.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Headless.Switch

  @doc ~S"""
  Renders a switch group component. Used to build switches with labes and descriptions.

  Uses `headless_switch_group` internally.

  ## Examples

      <.switch_group id="switch__group" class="flex items-center justify-between">
        <span class="flex flex-col flex-grow">
          <.switch_label
            id="switch__label"
            as="span"
            class="text-sm font-medium leading-6 text-gray-900"
          >
            Available to hire
          </.switch_label>
          <.switch_description id="switch__description" as="span" class="text-sm text-gray-500">
            Nulla amet tempus sit accumsan. Aliquet turpis sed sit lacinia.
          </.switch_description>
        </span>
        <.switch id="switch" checked />
      </.switch_group>
  """

  attr :id, :string,
    required: true,
    doc: "the id of the switch group (must conform <switch.id>__group)"

  attr :as, :string, default: "div"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_group(assigns) do
    ~H"""
    <.headless_switch_group id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_group>
    """
  end

  @doc ~S"""
  Renders a switch component. Used to build switches with labes and descriptions.

  Uses `headless_switch` internally.
  """

  attr :id, :string, required: true
  attr :as, :string, default: "button"
  attr :checked, :boolean, default: false, doc: "the checked state of the switch"
  attr :value, :string, default: "on", doc: "the checked value of the switch"
  attr :name, :string, default: nil, doc: "the field name of the switch if used inside a form"

  attr :class, :string,
    default:
      "bg-gray-200 group aria-checked:bg-indigo-600 w-11 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 relative inline-flex flex-shrink-0 h-6 transition-colors duration-200 ease-in-out border-2 border-transparent rounded-full cursor-pointer",
    doc: "the class of the switch"

  attr :rest, :global

  slot :inner_block

  def switch(assigns) do
    ~H"""
    <.headless_switch
      id={@id}
      as={@as}
      checked={@checked}
      value={@value}
      name={@name}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) || default_switch(assigns) %>
    </.headless_switch>
    """
  end

  defp default_switch(assigns) do
    ~H"""
    <span class="sr-only">Use setting</span>
    <span class="pointer-events-none relative inline-block h-5 w-5 translate-x-0 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out group-aria-checked:translate-x-5">
      <span
        class="absolute inset-0 flex h-full w-full items-center justify-center opacity-100 transition-opacity duration-200 ease-in group-aria-checked:opacity-0 group-aria-checked:duration-100 group-aria-checked:ease-out"
        aria-hidden="true"
      >
        <svg class="h-3 w-3 text-gray-400" fill="none" viewBox="0 0 12 12">
          <path
            d="M4 8l2-2m0 0l2-2M6 6L4 4m2 2l2 2"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
      </span>
      <span
        class="absolute inset-0 flex h-full w-full items-center justify-center opacity-0 transition-opacity duration-100 ease-out group-aria-checked:opacity-100 group-aria-checked:duration-200 group-aria-checked:ease-in"
        aria-hidden="true"
      >
        <svg class="h-3 w-3 text-indigo-600" fill="currentColor" viewBox="0 0 12 12">
          <path d="M3.707 5.293a1 1 0 00-1.414 1.414l1.414-1.414zM5 8l-.707.707a1 1 0 001.414 0L5 8zm4.707-3.293a1 1 0 00-1.414-1.414l1.414 1.414zm-7.414 2l2 2 1.414-1.414-2-2-1.414 1.414zm3.414 2l4-4-1.414-1.414-4 4 1.414 1.414z" />
        </svg>
      </span>
    </span>
    """
  end

  @doc ~S"""
  Renders a switch label component. Used to build switches with labes and descriptions.

  Uses `headless_switch_label` internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the switch label (must conform <switch.id>__label)"

  attr :passive, :boolean,
    default: false,
    doc:
      "set to true if you want to use the switch label as a passive label which does not toggle the switch"

  attr :as, :string, default: "label"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_label(assigns) do
    ~H"""
    <.headless_switch_label id={@id} as={@as} passive={@passive} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_label>
    """
  end

  @doc ~S"""
  Renders a switch description component. Used to build switches with labes and descriptions.

  Uses `headless_switch_description` internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the switch description (must conform <switch.id>__description)"

  attr :as, :string, default: "p"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_description(assigns) do
    ~H"""
    <.headless_switch_description id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_description>
    """
  end
end
