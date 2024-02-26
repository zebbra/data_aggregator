defmodule Storybook.Blocks.PageHeader do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks
  alias DataAggregatorWeb.Components

  def layout, do: :one_column

  def function, do: &Blocks.Header.page_header/1

  def imports,
    do: [
      {Blocks.SecondaryNavigation, [secondary_navigation: 1, secondary_navigation_item: 1]},
      {Components.Breadcrumbs, [breadcrumbs: 1]},
      {Components.Icon, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title_class: "px-6 lg:px-8"
        },
        slots: [
          "Hello World"
        ]
      },
      %Variation{
        id: :with_a_subtitle,
        attributes: %{
          title_class: "px-6 lg:px-8"
        },
        slots: [
          """
          Hello World
          <:subtitle>I'm a header subtitle</:subtitle>
          """
        ]
      },
      %Variation{
        id: :with_actions,
        attributes: %{
          title_class: "px-6 lg:px-8"
        },
        slots: [
          """
          Hello World
          <:subtitle>I'm a header subtitle</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          """
        ]
      },
      %Variation{
        id: :with_actions_and_breadcrumbs,
        attributes: %{
          title_class: "px-6 lg:px-8 max-lg:mt-2"
        },
        slots: [
          """
          <:breadcrumbs class="px-6 lg:px-8 text-sm text-base-content/60 font-medium">
            <.breadcrumbs items={#{inspect(breadcrumbs())}} />
          </:breadcrumbs>
          Hello World
          <:subtitle>I'm a header subtitle</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          """
        ]
      },
      %Variation{
        id: :with_actions_long,
        attributes: %{
          title_class: "px-6 lg:px-8"
        },
        slots: [
          """
          This is a very very very long title to test what happens on the screen. Let's have a look at it.
          <:subtitle>This is alos a very very very long subtitle to test what happens on the screen. Let's have a look at it as well</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          """
        ]
      },
      %Variation{
        id: :with_actions_long_with_breadcrumbs,
        attributes: %{
          title_class: "px-6 lg:px-8 max-lg:mt-2",
          break_at: "sm"
        },
        slots: [
          """
          <:breadcrumbs class="px-6 lg:px-8 text-sm text-base-content/60 font-medium">
            <.breadcrumbs items={#{inspect(breadcrumbs())}} />
          </:breadcrumbs>
          This is a very very very long title to test what happens on the screen. Let's have a look at it.
          <:subtitle>This is alos a very very very long subtitle to test what happens on the screen. Let's have a look at it as well</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          """
        ]
      },
      %Variation{
        id: :with_secondary_navigation,
        attributes: %{
          title_class: "px-6 lg:px-8"
        },
        slots: [
          """
          Hello World
          <:subtitle>I'm a header subtitle</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          <:navbar>
            <.secondary_navigation class="mt-6">
              <.secondary_navigation_item label="Overview" href="#" active />
              <.secondary_navigation_item label="Details" href="#" />
              <.secondary_navigation_item label="Settings" href="#" />
            </.secondary_navigation>
          </:navbar>
          """
        ]
      },
      %Variation{
        id: :with_secondary_navigation_and_breadcrumbs,
        attributes: %{
          title_class: "px-6 lg:px-8 max-lg:mt-2"
        },
        slots: [
          """
          <:breadcrumbs class="px-6 lg:px-8 text-sm text-base-content/60 font-medium">
            <.breadcrumbs items={#{inspect(breadcrumbs())}} />
          </:breadcrumbs>
          Hello World
          <:subtitle>I'm a header subtitle</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          <:navbar>
            <.secondary_navigation class="mt-6" id="nav_2">
              <.secondary_navigation_item label="Overview" href="#" active />
              <.secondary_navigation_item label="Details" href="#" />
              <.secondary_navigation_item label="Settings" href="#" />
            </.secondary_navigation>
          </:navbar>
          """
        ]
      },
      %Variation{
        id: :with_actions_long_and_secondary_navigation_and_responsive_breadcrumbs,
        attributes: %{
          title_class: "px-6 lg:px-8 max-lg:mt-2",
          break_at: "sm"
        },
        slots: [
          """
          <:breadcrumbs class="px-6 lg:px-8 text-sm text-base-content/60 font-medium">
            <.breadcrumbs items={#{inspect(breadcrumbs())}} />
          </:breadcrumbs>
          This is a very very very long title to test what happens on the screen. Let's have a look at it.
          <:subtitle>This is alos a very very very long subtitle to test what happens on the screen. Let's have a look at it as well</:subtitle>
          <:actions>
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-link-mini" /> Link
            </button>
          </:actions>
          <:navbar>
            <.secondary_navigation class="mt-6" id="nav_3">
              <.secondary_navigation_item label="Overview" href="#" active />
              <.secondary_navigation_item label="Details" href="#" />
              <.secondary_navigation_item label="Settings" href="#" />
            </.secondary_navigation>
          </:navbar>
          """
        ]
      },
      %Variation{
        id: :complete_example,
        attributes: %{
          title_class: "px-6 lg:px-8 max-lg:mt-2",
          break_at: "sm"
        },
        slots: [
          """
          <:breadcrumbs class="sm:hidden">
            <div class="flex items-center justify-between px-6">
              <.breadcrumbs
                class="text-sm"
                items={[
                  %{label: "Jobs", link: "#"},
                  %{label: "Back End Developer", link: "#"}
                ]}
              />
              <button type="button" class="btn btn-primary btn-sm">
                <.icon name="hero-check-mini" /> Publish
              </button>
            </div>
          </:breadcrumbs>
          <:title>
            <.breadcrumbs
              class="max-sm:hidden text-base-content font-bold text-3xl tracking-tight"
              items={[
                %{label: "Jobs", link: "#"},
                %{label: "Back End Developer", link: "#"}
              ]}
            />
            <h2 class="text-base-content text-2xl font-bold max-sm:line-clamp-2 sm:text-3xl sm:hidden sm:truncate sm:tracking-tight">
              Back End Developer
            </h2>
          </:title>
          <:subtitle>
            Workcation is a property rental website. Etiam ullamcorper massa viverra consequat, consectetur id nulla tempus. Fringilla egestas justo massa purus sagittis malesuada aösdlkföasd lfjaösdlfjaösdlfjöasdlfjöasldfjaösdlsadöfkjsadölfj asdölfj asdölfjasdölfj.
          </:subtitle>
          <:actions class="max-sm:hidden">
            <button type="button" class="btn btn-primary max-sm:btn-sm">
              <.icon name="hero-check-mini" /> Publish
            </button>
          </:actions>
          <:navbar>
            <.secondary_navigation class="mt-6" id="nav-3">
              <.secondary_navigation_item label="Overview" href="#" active />
              <.secondary_navigation_item label="Details" href="#" />
              <.secondary_navigation_item label="Settings" href="#" />
            </.secondary_navigation>
          </:navbar>
          """
        ]
      }
    ]
  end

  defp breadcrumbs do
    [
      %{label: "Home", link: "#"},
      %{label: "Documents", link: "#"},
      %{label: "Details", link: "#"},
      %{label: "Payment", link: "#"},
      %{label: "Payment", link: "#"},
      %{label: "Payment", link: "#"},
      %{label: "Payment", link: "#"},
      %{label: "Add Card", link: "#"}
    ]
  end
end
