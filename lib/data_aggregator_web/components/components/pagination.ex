defmodule DataAggregatorWeb.Components.Pagination do
  @moduledoc """
  Pagination components. Wrapper around `AshPagify.Components.pagination/1`.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias AshPagify.Meta

  @doc """
  Renders a pagination component.

  ## Examples

      <.pagination meta={@meta} path="/" />
  """
  attr :meta, Meta,
    required: true,
    doc: """
    The meta information of the query as returned by the `AshPagify` query functions
    """

  attr :position, :string,
    default: "bottom",
    values: ~w(top bottom),
    doc: "The position of the pagination component. Can be `top` or `bottom`."

  attr :class, :string,
    default: nil,
    doc: "Additional classes to add to the pagination container."

  attr :path, :any,
    default: nil,
    doc: """
    If set, the current view is patched with updated query parameters when a
    pagination link is clicked.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `AshPagify.Components.build_path/3` for details.
    """

  def pagination(assigns) do
    ~H"""
    <div
      :if={AshPagify.Components.Pagination.show_pagination?(@meta)}
      class={[
        "border-black-white/10 flex items-baseline justify-between space-x-3 px-6 lg:px-8",
        @position == "top" && "border-y pb-4",
        @position == "bottom" && "border-t py-4",
        @class
      ]}
    >
      <div class="flex items-baseline justify-between">
        <span class="text-base-content mr-3 text-sm font-semibold sm:hidden">
          <%= mgettext(
            "%{pagination_from} - %{pagination_to} of %{pagination_total}",
            pagination_from: @meta.current_offset + 1,
            pagination_to: showing_to(@meta),
            pagination_total: @meta.total_count
          ) %>
        </span>
        <span class="text-base-content mr-3 text-sm font-semibold max-sm:hidden">
          <%= mgettext(
            "Showing %{pagination_from} to %{pagination_to} of %{pagination_total} entries",
            pagination_from: @meta.current_offset + 1,
            pagination_to: showing_to(@meta),
            pagination_total: @meta.total_count
          ) %>
        </span>
      </div>

      <div class="flex items-center justify-end space-x-3">
        <DataAggregatorWeb.Components.Dropdown.dropdown
          id={"set_limit_#{@position}"}
          class={
            class_names([
              "dropdown-end",
              @position == "bottom" && "dropdown-top",
              @position == "top" && "dropdown-bottom z-10"
            ])
          }
        >
          <:summary>
            <summary class="btn btn-sm">
              <span><%= @meta.current_limit %></span>
              <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-down-micro" />
            </summary>
          </:summary>
          <ul class={[
            "dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 w-16 gap-1 border p-2 shadow-2xl",
            @position == "top" && "mt-0.5",
            @position == "bottom" && "mb-0.5"
          ]}>
            <li>
              <.link
                :for={limit <- [15, 25, 50, 75, 100]}
                patch={
                  AshPagify.Components.build_path(
                    @path,
                    @meta.ash_pagify |> AshPagify.set_limit(limit),
                    for: @meta.resource,
                    default_scopes: @meta.default_scopes
                  )
                }
                class={link_class(limit, @meta.current_limit)}
              >
                <%= limit %>
              </.link>
            </li>
          </ul>
        </DataAggregatorWeb.Components.Dropdown.dropdown>
        <AshPagify.Components.pagination meta={@meta} path={@path} />
      </div>
    </div>
    """
  end

  defp link_class(number, current_limit) do
    if number == current_limit, do: "active"
  end

  defp showing_to(%AshPagify.Meta{current_limit: limit, current_offset: offset, total_count: total})
       when limit + offset > total do
    total
  end

  defp showing_to(%AshPagify.Meta{current_limit: limit, current_offset: offset}) do
    limit + offset
  end
end
