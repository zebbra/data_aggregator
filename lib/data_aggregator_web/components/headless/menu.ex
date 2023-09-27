defmodule DataAggregatorWeb.Headless.Menu do
  @moduledoc """
  Menus offer an easy way to build custom, accessible dropdown components with
  robust support for keyboard navigation.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a menu component.

  ## Examples

    <.menu id="menu">
      <.menu_button id="menu__button">
        <.span aria-hidden="true">...</.span>
        <.span class="sr-only">...</.span>
      </.menu_button>
      <.menu_items id="menu__items">
        <.menu_item id="menu__item-1" href="#">...</.menu_item>
      </.menu_items>
    </.menu>

  ## Usage

  The `Menu` component is a wrapper for the `MenuButton` and `MenuItems` components.
  It is responsible for managing the state of the menu and rendering the `MenuButton`
  and `MenuItems` components. It also provides the `showMenu` and `hideMenu` functions
  to show and hide the menu.
  The componen ids must follow the pattern `<id>__button`, `<id>__items`, and
  `<id>__<item-suffix>` to work properly.
  """
  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: "relative inline-block text-left"
  attr :rest, :global
  slot :inner_block, required: true

  def menu(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="Menu"
      phx-remove={hide_menu(@id)}
      id={@id}
      name={@as}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "button"

  attr :class, :string,
    default:
      "inline-flex w-full justify-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"

  attr :rest, :global
  slot :inner_block, required: true

  def menu_button(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="MenuButton"
      phx-click={@id |> root_id |> show_menu}
      id={@id}
      name={@as}
      type={(@as == "button" && "button") || @rest.type}
      aria-haspopup="true"
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "div"

  attr :class, :string,
    default:
      "ring-1 ring-black ring-opacity-5 focus:outline-none absolute right-0 z-10 mt-2 origin-top-right bg-white divide-y divide-gray-100 rounded-md shadow-lg"

  attr :width, :string, default: "w-56"
  attr :rest, :global
  slot :inner_block, required: true

  def menu_items(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="MenuItems"
      phx-click-away={JS.exec("phx-remove", to: "##{@id |> root_id}")}
      name={@as}
      id={@id}
      aria-labelledby={"#{@id |> root_id }__button"}
      aria-orientation="vertical"
      role="menu"
      class={["hidden", @width, @class]}
      tabindex="-1"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true

  attr :class, :string,
    default:
      "group aria-selected:bg-gray-100 focus:outline-none aria-selected:text-gray-900 flex justify-between cursor-pointer items-center px-4 py-2 text-sm text-gray-700"

  attr :rest, :global, include: ~w(navigate patch href replace method csrf_token disabled)
  attr :as, :string, default: nil
  slot :inner_block, required: true

  def menu_item(assigns) do
    ~H"""
    <%= if @as do %>
      <.dynamic_tag phx-hook="MenuItem" id={@id} role="menuitem" class={@class} {@rest} name={@as}>
        <%= render_slot(@inner_block) %>
      </.dynamic_tag>
    <% else %>
      <.link phx-hook="MenuItem" id={@id} role="menuitem" class={@class} {@rest}>
        <%= render_slot(@inner_block) %>
      </.link>
    <% end %>
    """
  end

  defp root_id(id) do
    id
    |> String.split("__")
    |> List.first()
  end

  defp show_menu(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}__items",
      time: 100,
      transition:
        {"transition ease-out duration-100", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id}-button")
    |> JS.set_attribute({"aria-controls", "#{id}__items"}, to: "##{id}__button")
  end

  defp hide_menu(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}__items",
      time: 75,
      transition:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}__button")
    |> JS.remove_attribute("aria-controls", to: "##{id}__button")
  end
end
