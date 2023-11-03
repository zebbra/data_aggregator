defmodule Storybook.HeadlessComponents.Menu do
  use PhoenixStorybook.Story, :component

  alias Elixir.DataAggregatorWeb.HeadlessComponents

  def function, do: &HeadlessComponents.menu/1

  def variations do
    [
      %Variation{
        id: :menu,
        slots: [
          """
          <HeadlessComponents.menu_button id="menu-single-menu__button">
            Menu 1
          </HeadlessComponents.menu_button>
          <HeadlessComponents.menu_items id="menu-single-menu__items">
            <div class="py-1" role="none">
              <HeadlessComponents.menu_item id="menu-single-menu__item-1" role="menuitem">
                Item 1
              </HeadlessComponents.menu_item>
              <HeadlessComponents.menu_item id="menu-single-menu__item-2" role="menuitem">
                Item 2
              </HeadlessComponents.menu_item>
              <HeadlessComponents.menu_item id="menu-single-menu__item-3" role="menuitem">
                Item 3
              </HeadlessComponents.menu_item>
            </div>
          </HeadlessComponents.menu_items>
          """
        ]
      }
    ]
  end
end
