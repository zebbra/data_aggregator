defmodule DataAggregatorWeb.Components.Pagination do
  @moduledoc """
  Renders offset pagination with generic styling.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Components.Button, only: [button: 1]
  import DataAggregatorWeb.Components.Form, only: [label: 1]
  import DataAggregatorWeb.Components.Menu

  @doc ~S"""
  Renders offset pagination with generic styling.
  """

  attr :page_meta, Ash.Page.Offset, required: true

  def pagination(assigns) do
    [from, to] = paginate_page_meta(assigns.page_meta)

    assigns =
      assigns
      |> assign(:from, from)
      |> assign(:to, to)

    ~H"""
    <div
      class="bg-gray-100/30 flex items-center justify-between border-y border-gray-200 px-4 py-4 dark:border-white/10 dark:bg-black/10 sm:px-6 lg:px-8"
      role="navigation"
    >
      <div class="flex flex-1 justify-between sm:hidden">
        <.button
          color="secondary"
          aria-label={~t"Previous"m}
          label={~t"Prev"m}
          disabled={@page_meta.offset == 0}
          phx-click="page:prev"
        />
        <.page_size_select id="page-size-select-mobile" current_limit={@page_meta.limit} />
        <.button
          color="secondary"
          class="rounded-md"
          aria-label={~t"Next"m}
          label={~t"Next"m}
          disabled={@page_meta.more? == false}
          phx-click="page:next"
        />
      </div>
      <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div :if={@page_meta.count > 0}>
          <p class="text-sm text-gray-700 dark:text-gray-400">
            <%= ~t"Showing"m %> <span class="font-medium"><%= @from %></span>
            <%= ~t"to"m %>
            <span class="font-medium"><%= @to %></span>
            <%= ~t"of"m %> <span class="font-medium"><%= @page_meta.count %></span>
            <%= ~t"results"m %>
          </p>
        </div>
        <div :if={@page_meta.count == 0}>
          <p class="text-sm text-gray-700 dark:text-gray-400">
            <%= ~t"No results"m %>
          </p>
        </div>
        <div class="flex items-center">
          <.page_size_select id="page-size-select" current_limit={@page_meta.limit} />
          <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <.button
              color="secondary"
              class="focus:z-10 rounded-r-none"
              aria-label={~t"Previous"m}
              label={~t"Prev"m}
              disabled={@page_meta.offset == 0}
              phx-click="page:prev"
            />
            <.button
              color="secondary"
              class="focus:z-10 -ml-px rounded-l-none"
              aria-label={~t"Next"m}
              label={~t"Next"m}
              disabled={@page_meta.more? == false}
              phx-click="page:next"
            />
          </nav>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :current_limit, :integer, required: true

  defp page_size_select(assigns) do
    ~H"""
    <div class="mr-2 flex items-center space-x-2">
      <.label for={@id}>
        <%= ~t"Page size"m %>
      </.label>
      <.menu id={@id} label={@current_limit} position="bottom-right" width="w-[4.5rem]">
        <div class="py-1" role="none">
          <.menu_item
            :for={page_size <- [5, 10, 15, 20, 25, 50, 100]}
            id={@id <> "__item-" <> to_string(page_size)}
            as="div"
            phx-click="page:change"
            phx-value-limit={page_size}
          >
            <%= page_size %>
            <span :if={@current_limit == page_size} class="font-bold text-cyan-600">
              &check;
            </span>
          </.menu_item>
        </div>
      </.menu>
    </div>
    """
  end

  # Extract from and to values from page_meta
  defp paginate_page_meta(page_meta) do
    from = page_meta.offset + 1

    to =
      if page_meta.offset + page_meta.limit > page_meta.count do
        page_meta.count
      else
        page_meta.offset + page_meta.limit
      end

    [from, to]
  end
end
