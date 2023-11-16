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
    <div class="sm:px-6 lg:px-8 dark:border-white/10 px-4 border-b border-gray-200">
      <div class="sm:mt-6 lg:mt-8 flow-root mt-4">
        <div class="table-container sm:-mx-6 lg:-mx-8 no-scrollbar overscroll-x-contain -mx-4 -my-2 overflow-x-auto">
          <div class="inline-block min-w-full py-2 align-middle">
            <table
              role="table"
              class="will-change-scroll dark:divide-gray-700 min-w-full divide-y divide-gray-300 table-auto"
            >
              <thead role="rowgroup">
                <tr role="row">
                  <th
                    :for={col <- @col}
                    role="columnheader"
                    scope="col"
                    class="first:pl-4 last:pl-3 first:pr-3 last:pr-4 dark:text-white first:sm:pl-6 first:lg:pl-8 last:sm:pr-6 last:lg:pr-8 py-3.5 px-3 text-sm font-semibold tracking-wide text-left text-gray-900 uppercase whitespace-nowrap"
                  >
                    <%= col[:label] %>
                  </th>
                  <th
                    :if={@action != []}
                    role="columnheader"
                    scope="col"
                    class="sm:pr-6 lg:pr-8 relative py-3.5 pr-4 pl-3"
                  >
                    <span class="sr-only"><%= gettext("Actions") %></span>
                  </th>
                </tr>
              </thead>
              <tbody
                id={@id}
                role="rowgroup"
                phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
                class="dark:divide-gray-800 divide-y divide-gray-200"
              >
                <tr
                  :for={row <- @rows}
                  role="rowgroup"
                  id={@row_id && @row_id.(row)}
                  class="group dark:hover:bg-black/10 hover:bg-gray-400/10"
                >
                  <td
                    :for={{col, _i} <- Enum.with_index(@col)}
                    phx-click={@row_click && @row_click.(row)}
                    role="cell"
                    class={[
                      "whitespace-nowrap py-4 px-3 first:pl-4 first:pr-3 last:pl-3 last:pr-4 text-sm first:font-medium text-gray-900 dark:text-white first:sm:pl-6 first:lg:pl-8 last:sm:pr-6 last:lg:pr-8",
                      @row_click && "hover:cursor-pointer"
                    ]}
                  >
                    <%= render_slot(col, @row_item.(row)) %>
                  </td>
                  <td
                    :if={@action != []}
                    role="cell"
                    class="whitespace-nowrap sm:pr-6 lg:pr-8 relative py-4 pl-3 pr-4 text-sm font-medium text-right"
                  >
                    <span
                      :for={action <- @action}
                      class="hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 relative ml-4 font-semibold leading-6 text-indigo-600"
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
