defmodule Storybook.Components.Drawer do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Drawer.drawer/1
  def imports, do: [{Components.Icon, [icon: 1]}]

  def variations do
    [
      %Variation{
        id: :drawer_right,
        attributes: %{
          class: "drawer-end"
        },
        slots: [
          content("drawer-single-drawer-right"),
          side("drawer-single-drawer-right")
        ]
      },
      %Variation{
        id: :drawer_left,
        slots: [
          content("drawer-single-drawer-left"),
          side("drawer-single-drawer-left")
        ]
      },
      %Variation{
        id: :drawer_with_overlay,
        attributes: %{
          class: "drawer-end",
          overlay: true
        },
        slots: [
          content("drawer-single-drawer-with-overlay"),
          side("drawer-single-drawer-with-overlay")
        ]
      },
      %Variation{
        id: :drawer_responsive,
        attributes: %{
          class: "drawer-end 3xl:drawer-open",
          overlay: true
        },
        slots: [
          content("drawer-single-drawer-responsive"),
          side()
        ]
      }
    ]
  end

  def side() do
    """
    <:side>
      <div class="bg-base-100 border-black-white/10 min-h-screen w-80 border-x p-4">
        Sidebar content
      </div>
    </:side>
    """
  end

  def side(id) do
    """
    <:side>
      <div class="bg-base-100 border-black-white/10 min-h-screen w-80 border-x p-4">
        <label
          aria-label="Close drawer"
          for="#{id}"
          class="btn btn-square btn-ghost drawer-button"
        >
          <.icon name="hero-x-mark-mini" class="size-5 md:size-6" />
        </label>
        Sidebar content
      </div>
    </:side>
    """
  end

  def content(id) do
    """
    <section>
      <label
        aria-label="Open drawer"
        for="#{id}"
        class="btn btn-square btn-ghost drawer-button"
      >
        <.icon name="hero-bars-3-mini" class="size-5 md:size-6" />
      </label>
      Main content
    </section>
    """
  end
end
