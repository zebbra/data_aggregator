defmodule DataAggregatorWeb.Components.Table do
  @moduledoc """
  Renders a table for streams with generic tailwindui styling.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext

  @doc ~S"""
  Renders a table for streams with generic tailwindui styling.

  ## Examples

      <.table id="users" rows={@streams.results}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true, doc: "the list of rows (a stream) to render"
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string, doc: "the label for the column"
    attr :field, :string, doc: "the field for the column"
    attr :align, :string, doc: "the alignment of the column (left, center, right)"
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="border-b border-gray-200 px-4 dark:border-white/10 sm:px-6 lg:px-8">
      <div class="mt-4 flow-root sm:mt-6 lg:mt-8">
        <div class="table-container no-scrollbar -mx-4 -my-2 overflow-x-auto overscroll-x-contain sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle">
            <table
              role="table"
              class="min-w-full table-auto divide-y divide-gray-300 will-change-scroll dark:divide-gray-700"
            >
              <thead role="rowgroup">
                <tr role="row">
                  <th
                    :for={col <- @col}
                    role="columnheader"
                    scope="col"
                    class="whitespace-nowrap px-3 py-3.5 text-left text-sm font-semibold uppercase tracking-wide text-gray-900 first:pr-3 first:pl-4 last:pr-4 last:pl-3 dark:text-white sm:first:pl-6 sm:last:pr-6 lg:first:pl-8 lg:last:pr-8"
                  >
                    <%= col[:label] %>
                  </th>
                  <th
                    :if={@action != []}
                    role="columnheader"
                    scope="col"
                    class="relative py-3.5 pr-4 pl-3 sm:pr-6 lg:pr-8"
                  >
                    <span class="sr-only"><%= gettext("Actions") %></span>
                  </th>
                </tr>
              </thead>
              <tbody
                id={@id}
                role="rowgroup"
                phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
                class="divide-y divide-gray-200 dark:divide-gray-800"
              >
                <tr
                  :for={row <- @rows}
                  role="rowgroup"
                  id={@row_id && @row_id.(row)}
                  class="group hover:bg-gray-400/10 dark:hover:bg-black/10"
                >
                  <td
                    :for={{col, _i} <- Enum.with_index(@col)}
                    phx-click={@row_click && @row_click.(row)}
                    role="cell"
                    class={[
                      "whitespace-nowrap px-3 py-4 text-sm text-gray-900 first:pr-3 first:pl-4 first:font-medium last:pr-4 last:pl-3 dark:text-white sm:first:pl-6 sm:last:pr-6 lg:first:pl-8 lg:last:pr-8",
                      @row_click && "hover:cursor-pointer"
                    ]}
                  >
                    <%= render_slot(col, @row_item.(row)) %>
                  </td>
                  <td
                    :if={@action != []}
                    role="cell"
                    class="relative whitespace-nowrap py-4 pr-4 pl-3 text-right text-sm font-medium sm:pr-6 lg:pr-8"
                  >
                    <span
                      :for={action <- @action}
                      class="relative ml-4 font-semibold leading-6 text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300"
                    >
                      <%= render_slot(action, @row_item.(row)) %>
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
