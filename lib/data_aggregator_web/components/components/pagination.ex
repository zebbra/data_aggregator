defmodule DataAggregatorWeb.Components.Pagination do
  @moduledoc """
  Pagination components. Wrapper around `Pagify.Components.pagination/1`.
  """

  use Phoenix.Component

  alias Pagify.Meta

  @doc """
  Renders a pagination component.

  ## Examples

      <.pagination meta={@meta} path="/" />
  """
  attr :meta, Meta,
    required: true,
    doc: """
    The meta information of the query as returned by the `Pagify` query functions
    """

  attr :path, :any,
    default: nil,
    doc: """
    If set, the current view is patched with updated query parameters when a
    pagination link is clicked.

    The value must be either a URI string (Phoenix verified route), an MFA or FA
    tuple (Phoenix route helper), or a 1-ary path builder function. See
    `Pagify.Components.build_path/3` for details.
    """

  def pagination(assigns) do
    ~H"""
    <div
      :if={Pagify.Components.Pagination.show_pagination?(@meta)}
      class="border-black-white/10 flex items-center justify-end space-x-3 border-t px-6 py-4 lg:px-8"
    >
      <DataAggregatorWeb.Components.Dropdown.dropdown id="set_limit" class="dropdown-end dropdown-top">
        <:summary>
          <summary class="btn btn-sm">
            <span><%= @meta.current_limit %></span>
            <DataAggregatorWeb.Components.Icon.icon name="hero-chevron-down-micro" />
          </summary>
        </:summary>
        <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 mb-0.5 w-16 gap-1 border p-2 shadow-2xl">
          <li>
            <.link
              :for={limit <- [15, 25, 50, 75, 100]}
              patch={
                Pagify.Components.build_path(@path, @meta.pagify |> Pagify.set_limit(limit),
                  for: @meta.resource
                )
              }
              class={link_class(limit, @meta.current_limit)}
            >
              <%= limit %>
            </.link>
          </li>
        </ul>
      </DataAggregatorWeb.Components.Dropdown.dropdown>
      <Pagify.Components.pagination meta={@meta} path={@path} />
    </div>
    """
  end

  defp link_class(number, current_limit) do
    if number == current_limit, do: "active"
  end
end
