defmodule DataAggregatorWeb.Components do
  @moduledoc """
  This module is used to import all components, blocks, and live_components at once.
  """

  use Phoenix.Component

  defmacro __using__(_) do
    quote do
      use DataAggregatorWeb.LiveComponents.ThemeSelect

      import DataAggregatorWeb.Components.Alert
      import DataAggregatorWeb.Components.Badge
      import DataAggregatorWeb.Components.Breadcrumbs
      import DataAggregatorWeb.Components.Combobox
      import DataAggregatorWeb.Components.Drawer
      import DataAggregatorWeb.Components.Dropdown
      import DataAggregatorWeb.Components.Field
      import DataAggregatorWeb.Components.Flash
      import DataAggregatorWeb.Components.Form
      import DataAggregatorWeb.Components.Icon
      import DataAggregatorWeb.Components.Input
      import DataAggregatorWeb.Components.List
      import DataAggregatorWeb.Components.LocaleSelect
      import DataAggregatorWeb.Components.Modal
      import DataAggregatorWeb.Components.Pagination
      import DataAggregatorWeb.Components.Progress
      import DataAggregatorWeb.Components.Transitions
      import Pagify.Components, only: [table: 1, build_path: 2, build_path: 3]
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
        class: "no-scrollbar overflow-x-auto py-4"
      ],
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
          [class: "hover border-base-content/10"]
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

  defp symbol_asc do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-up-micro" class="size-5" />
    """
  end

  def symbol_desc do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-down-micro" class="size-5" />
    """
  end

  def previous_link_content do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-left-micro" />
    """
  end

  def next_link_content do
    assigns = %{}

    ~H"""
    <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-right-micro" />
    """
  end
end
