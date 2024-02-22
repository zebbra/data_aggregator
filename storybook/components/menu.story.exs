defmodule Storybook.Components.Menu do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Button
  alias DataAggregatorWeb.Components.Menu

  def function, do: &Menu.menu/1

  def imports do
    [{Menu, [menu_button: 1, menu_item: 1, menu_items: 1]}, {Button, [button: 1]}]
  end

  def variations do
    [
      %Variation{
        id: :menu,
        attributes: %{
          label: "Menu 1",
          width: "w-20"
        },
        slots: [
          """
          <div class="py-1" role="none">
            <.menu_item id="menu-single-menu__item-1" role="menuitem">
              Item 1
            </.menu_item>
            <.menu_item id="menu-single-menu__item-2" role="menuitem">
              Item 2
            </.menu_item>
            <.menu_item id="menu-single-menu__item-3" role="menuitem">
              Item 3
            </.menu_item>
          </div>
          """
        ]
      },
      %Variation{
        id: :custom_label,
        slots: [
          """
          <:menu_button>
            <.menu_button id="menu-single-custom-label__button">
              Custom label
            </.menu_button>
          </:menu_button>
          <div class="py-1" role="none">
            <.menu_item id="menu-single-custom-label__item-1" role="menuitem">
              Item 1
            </.menu_item>
            <.menu_item id="menu-single-custom-label__item-2" role="menuitem">
              Item 2
            </.menu_item>
            <.menu_item id="menu-single-custom-label__item-3" role="menuitem">
              Item 3
            </.menu_item>
          </div>
          """
        ]
      },
      %Variation{
        id: :custom_label_and_container,
        attributes: %{
          custom_container: true
        },
        slots: [
          """
            <.menu_button id="menu-single-custom-label-and-container__button">
              Custom container
            </.menu_button>
          <.menu_items id="menu-single-custom-label-and-container__items" width="w-20">
            <div class="py-1" role="none">
              <.menu_item id="menu-single-custom-label-and-container__item-1" role="menuitem">
                Item 1
              </.menu_item>
              <.menu_item id="menu-single-custom-label-and-container__item-2" role="menuitem">
                Item 2
              </.menu_item>
              <.menu_item id="menu-single-custom-label-and-container__item-3" role="menuitem">
                Item 3
              </.menu_item>
              </div>
            </.menu_items>
          """
        ]
      }
    ]
  end
end
