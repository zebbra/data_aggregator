defmodule DataAggregatorWeb.Components.Menu do
  @moduledoc """
  Renders a menu with generic tailwindui styling.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Button, only: [button: 1]
  import DataAggregatorWeb.Headless.Menu

  @doc ~S"""
  Menu component for dropdowns with tailwindui style.

  Uses the `headless_menu` component internally.

  ## Examples

      <.menu id="menu">
        <.menu_button id="menu__button">
          Menu 1
        </.menu_button>
        <.menu_items id="menu__items">
          <%= for {_key, items} <- @items do %>
            <div class="py-1" role="none">
              <%= for item <- items do %>
                <.menu_item id={"menu__item-#{item.id}"} patch="#" disabled={item.disabled}>
                  <.icon
                    name={item.icon}
                    class="group-hover:text-gray-500 w-5 h-5 mr-3 text-gray-400"
                  />
                  <span><%= item.name %></span>
                </.menu_item>
              <% end %>
            </div>
          <% end %>
        </.menu_items>
      </.menu>
  """

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: nil, doc: "the class of the menu"
  attr :label, :string, default: nil, doc: "the label of the menu button"

  attr :custom_container, :boolean,
    default: false,
    doc: "set to true if you want to use your own menu_items container"

  attr :width, :string, default: "w-56", doc: "the width of the menu items container"

  attr :position, :string,
    default: "top-right",
    doc: "the position of the menu items (see position_class/1)"

  attr :hide_transition, :map,
    default: {"transition ease-in duration-75", "transform opacity-100 scale-100", "transform opacity-0 scale-95"},
    doc: "the transition for hiding the menu"

  attr :rest, :global

  slot :inner_block, required: true
  slot :menu_button, doc: "the menu button slot (for custom label with custom container)"

  def menu(assigns) do
    ~H"""
    <.headless_menu
      id={@id}
      as={@as}
      class={["relative inline-block text-left", @class]}
      hide_transition={@hide_transition}
      {@rest}
    >
      <.menu_button :if={@label != nil} id={@id <> "__button"} as="div" class="">
        <.button color="secondary" label={@label} />
      </.menu_button>
      <%= if @custom_container do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= if @label == nil do %>
          <%= render_slot(@menu_button) %>
        <% end %>
        <.menu_items id={@id <> "__items"} width={@width} position={@position}>
          <%= render_slot(@inner_block) %>
        </.menu_items>
      <% end %>
    </.headless_menu>
    """
  end

  @doc ~S"""
  Menu button component for dropdowns with tailwindui style.

  Uses the `headless_menu_button` component internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the menu button (must conform <menu.id>__button)"

  attr :as, :string, default: "button"

  attr :class, :string,
    default:
      "inline-flex w-full justify-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
    doc: "the class of the menu button"

  attr :show_transition, :map,
    default: {"transition ease-out duration-100", "transform opacity-0 scale-95", "transform opacity-100 scale-100"},
    doc: "the transition for showing the menu"

  attr :rest, :global

  slot :inner_block, required: true

  def menu_button(assigns) do
    ~H"""
    <.headless_menu_button id={@id} as={@as} class={@class} show_transition={@show_transition} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu_button>
    """
  end

  @doc ~S"""
  Menu items component for dropdowns with tailwindui style.

  Uses the `headless_menu_items` component internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the menu items (must conform <menu.id>__items)"

  attr :as, :string, default: "div"

  attr :class, :string,
    default:
      "ring-1 ring-black ring-opacity-5 focus:outline-none absolute right-0 bg-white divide-y divide-gray-100 rounded-md shadow-lg",
    doc: "the class of the menu items"

  attr :position, :string,
    default: "top-right",
    doc: "the position of the menu items (see position_class/1)"

  attr :width, :string, default: "w-56"
  attr :rest, :global

  slot :inner_block, required: true

  def menu_items(assigns) do
    ~H"""
    <.headless_menu_items
      id={@id}
      as={@as}
      class={Enum.join([@class, position_class(@position)])}
      width={@width}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.headless_menu_items>
    """
  end

  defp position_class(position) do
    case position do
      "bottom-right" -> "origin-bottom-right mb-11 bottom-0"
      _ -> "origin-top-right mt-2"
    end
  end

  @doc ~S"""
  Menu item component for dropdowns with tailwindui style.

  Uses the `headless_menu_item` component internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the menu item (must conform <menu.id>__<item-suffix>)"

  attr :class, :string,
    default:
      "group bg-white aria-selected:bg-gray-100 focus:outline-none aria-selected:text-gray-900 flex justify-between cursor-pointer items-center px-4 py-2 text-sm text-gray-700 w-full"

  attr :rest, :global, include: ~w(navigate patch href replace method csrf_token disabled)
  attr :as, :string, default: nil

  slot :inner_block, required: true

  def menu_item(assigns) do
    ~H"""
    <.headless_menu_item id={@id} as={@as} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu_item>
    """
  end
end
