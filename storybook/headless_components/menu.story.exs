defmodule Storybook.HeadlessComponents.Menu do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.HeadlessComponents

  def function, do: &HeadlessComponents.menu/1

  def imports do
    [{HeadlessComponents, [menu_button: 1, menu_item: 1, menu_items: 1]}]
  end

  def variations do
    [
      %Variation{
        id: :menu,
        slots: [
          """
          <.menu_button id="menu-single-menu__button">
            Menu 1
          </.menu_button>
          <.menu_items id="menu-single-menu__items">
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
          </.menu_items>
          """
        ]
      }
    ]
  end
end
