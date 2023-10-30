defmodule DataAggregatorWeb.Headless.Menu do
  @moduledoc """
  Menus offer an easy way to build custom, accessible dropdown components with
  robust support for keyboard navigation.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Headless.Helpers

  @doc """
  Renders a menu component.

  ## Examples

  <.headless_menu id="menu">
    <.headless_menu_button id="menu__button">
      Button
    </.headless_menu_button>
    <.headless_menu_items id="menu__items">
      <div class="py-1" role="none">
        <.headless_menu_item id="menu__item-1" href="#">Item 1</.headless_menu_item>
        <.headless_menu_item id="menu__item-2" href="#">Item 2</.headless_menu_item>
        <.headless_menu_item id="menu__item-3" href="#">Item 3</.headless_menu_item>
      </div>
    </.headless_menu_items>
  </.headless_menu>

  ## Usage

  The `HeadlessMenu` component is a wrapper for the `HeadlessMenuButton` and `HeadlessMenuItems` components.
  It is responsible for managing the state of the menu and rendering the `HeadlessMenuButton`
  and `HeadlessMenuItems` components. It also provides the `showMenu` and `hideMenu` functions
  to show and hide the menu.
  The componen ids must follow the pattern `<id>__button`, `<id>__items`, and
  `<id>__<item-suffix>` to work properly.
  """
  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: nil
  attr :hide_transition, :map, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def headless_menu(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="Menu"
      phx-remove={hide_menu(@id, @hide_transition)}
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
  attr :class, :string, default: nil
  attr :show_transition, :map, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def headless_menu_button(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="MenuButton"
      phx-click={@id |> root_id |> show_menu(@show_transition)}
      id={@id}
      name={@as}
      type={(@as == "button" && "button") || @rest[:type]}
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
  attr :class, :string, default: nil
  attr :width, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def headless_menu_items(assigns) do
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
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(navigate patch href replace method csrf_token disabled)
  attr :as, :string, default: nil
  slot :inner_block, required: true

  def headless_menu_item(assigns) do
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

  defp show_menu(js \\ %JS{}, id, transition) when is_binary(id) do
    time = extract_duration(transition)

    js
    |> JS.show(
      to: "##{id}__items",
      time: time,
      transition: transition
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: "##{id}__button")
    |> JS.set_attribute({"aria-controls", "#{id}__items"}, to: "##{id}__button")
  end

  defp hide_menu(js \\ %JS{}, id, transition) do
    time = extract_duration(transition)

    js
    |> JS.hide(
      to: "##{id}__items",
      time: time,
      transition: transition
    )
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}__button")
    |> JS.remove_attribute("aria-controls", to: "##{id}__button")
  end
end
