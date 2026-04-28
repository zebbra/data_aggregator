defmodule DataAggregatorWeb.Components do
  @moduledoc """
  This module is used to import all components, and live_components at once.

  ## Introduction

  We use [daisyUI](https://daisyui.com) in conjunction with [Tailwind CSS](https://tailwindcss.com)
  to style our components. The components provided in this module are wrapper components around
  the daisyUI components to make them easier to use in Phoenix LiveView.

  ## Installation

  Make sure to install and setup Tailwind CSS in your Phoenix project. If you create a new Phoenix
  project with Tailwind CSS, you can skip this step.

  Furthermore, the following npm packages are required to use the components:

  ```bash
  cd assets && npm install daisyui tom-select
  ```

  Add the required `tailwind.config.js` configuration to your project:

  ```javascript
  module.exports = {
    // ...

    theme: {
      extend: {
        colors: {
          "black-white": "oklch(var(--black-white) / <alpha-value>)",
        },
        screens: {
          "3xl": "1850px",
        },
      },
    },
    daisyui: {
      themes: [
        {
          light: {
            ...themes.light,
            "--black-white": "0% 0 0",
          },
        },
        {
          dark: {
            ...themes.dark,
            "--black-white": "100% 0 0",
          },
        },
      ],
    },
    plugins: [
      // DaisyUI
      require("daisyui"),
      // ...
    ],

    // ...
  }
  ```

  To use the components in your project, copy over the following folders into your project:

  - `assets/css` - Contains the CSS files for the components.
  - `assets/js` - Contains the JavaScript files for the components.
  - `blocks` - Contains blocks to build a coherent layout with consistent spacing and responsive behaviour.
  - `components` - Contains the components that are used to build the content of the page.
  - `layouts` - Contains the layout components that are used to build the layout of the page.
  - `live_components` - Contains the live components.

  ## Customization

  Most of the components have a `class` attribute that allows you to add custom classes to the
  component. This allows you to customize the component to your needs. Furthermore, you can also
  use the `slot` attribute to add custom content to the component. Check the documentation of the
  component for more information.
  """

  use Phoenix.Component

  defmacro __using__(_) do
    quote do
      import AshPagify.Components,
        only: [table: 1, build_path: 2, build_path: 3, build_scope_path: 3]

      import DataAggregatorWeb.Components.Alert
      import DataAggregatorWeb.Components.AsyncData
      import DataAggregatorWeb.Components.Attachment
      import DataAggregatorWeb.Components.Badge
      import DataAggregatorWeb.Components.Breadcrumbs
      import DataAggregatorWeb.Components.Button
      import DataAggregatorWeb.Components.Combobox
      import DataAggregatorWeb.Components.Drawer
      import DataAggregatorWeb.Components.Dropdown
      import DataAggregatorWeb.Components.EnvInfo
      import DataAggregatorWeb.Components.Field
      import DataAggregatorWeb.Components.FieldGroup
      import DataAggregatorWeb.Components.Flash
      import DataAggregatorWeb.Components.Form
      import DataAggregatorWeb.Components.FuiTooltip
      import DataAggregatorWeb.Components.Icon
      import DataAggregatorWeb.Components.Input
      import DataAggregatorWeb.Components.List
      import DataAggregatorWeb.Components.LocaleSelect
      import DataAggregatorWeb.Components.Modal
      import DataAggregatorWeb.Components.Notification
      import DataAggregatorWeb.Components.Pagination
      import DataAggregatorWeb.Components.Progress
      import DataAggregatorWeb.Components.Tab
      import DataAggregatorWeb.Components.Transitions
      import DataAggregatorWeb.LiveComponents.ThemeSelect
    end
  end

  def pagination_opts do
    [
      current_link_attrs: [
        class: "join-item btn btn-sm btn-active max-sm:hidden"
      ],
      disabled_class: "text-base-content/20 pointer-events-none",
      ellipsis_attrs: [
        class: "join-item btn btn-sm text-base-content/20 pointer-events-none max-sm:hidden",
        aria: [hidden: "true"]
      ],
      next_link_attrs: [
        class: "join-item btn btn-sm"
      ],
      next_link_content: next_link_content(),
      page_links: {:ellipsis, 3},
      pagination_link_attrs: [class: "join-item btn btn-sm max-sm:hidden"],
      previous_link_attrs: [
        class: "join-item btn btn-sm"
      ],
      previous_link_content: previous_link_content(),
      wrapper_attrs: [
        class: "join"
      ]
    ]
  end

  def table_opts do
    [
      container: true,
      container_attrs: [
        class: "overflow-x-auto py-4"
      ],
      no_results_content: "",
      loading_content: loading_content(),
      error_content: error_content(),
      symbol_asc: symbol_asc(),
      symbol_desc: symbol_desc(),
      symbol_attrs: [
        class: "ml-2 flex-none rounded bg-base-200 text-base-content group-hover:bg-base-300 h-5"
      ],
      table_attrs: [
        class: "text-base-content table"
      ],
      tbody_td_attrs: [
        class: "first:pl-6 last:pr-6 lg:first:pl-8 lg:last:pr-8"
      ],
      tbody_tr_attrs: fn _item, assigns ->
        if Map.get(assigns, :row_click, false) do
          [class: "hover:bg-base-300/30 border-base-content/10 cursor-pointer"]
        else
          [class: "border-base-content/10"]
        end
      end,
      th_wrapper_attrs: [
        class: "inline-flex items-center h-5"
      ],
      thead_th_attrs: [
        class: "first:pl-6 last:pr-6 lg:first:pl-8 lg:last:pr-8 group"
      ],
      thead_tr_attrs: [
        class: "border-base-content/10"
      ],
      limit_order_by: 1
    ]
  end

  defp loading_content do
    assigns = %{}

    ~H"""
    <div class="skeleton my-3 py-3" />
    """
  end

  defp error_content do
    assigns = %{}

    ~H"""
    <div class="flex h-64 items-center justify-center">
      <div class="text-center">
        <DataAggregatorWeb.Components.Icon.icon
          name="hero-exclamation-triangle-mini"
          class="text-base-content/50 size-10 bg-error"
        />
        <h3 class="text-base-content mt-2 text-sm font-semibold">There was an error</h3>
        <p class="text-base-content/60 mt-1 text-sm">
          We could not load the records, please try again later
        </p>
      </div>
    </div>
    """
  end

  defp symbol_asc do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-up-micro" class="size-5" />
    """
  end

  defp symbol_desc do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-down-micro" class="size-5" />
    """
  end

  defp previous_link_content do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-left-micro" />
    """
  end

  defp next_link_content do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-right-micro" />
    """
  end
end
