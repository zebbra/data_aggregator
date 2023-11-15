defmodule DataAggregatorWeb.Components.Datatable do
  @moduledoc """
  Renders a datatable for streams with generic tailwindui styling.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.QueryBuilder

  @doc ~S"""
  Renders a datatable for streams with generic tailwindui styling.

  ## Examples

      <.datatable id="users" rows={@streams.results}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.datatable>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true, doc: "the list of rows (a stream) to render"
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :sort, :string, default: nil, doc: "the current sort order"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string, doc: "the label for the column"
    attr :field, :string, doc: "the field for the column"
    attr :sort, :boolean, doc: "the sort flag for the column"
    attr :align, :string, doc: "the alignment of the column (left, center, right)"
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def datatable(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    assigns = assign(assigns, :sort_dir, current_sort_dir(assigns.sort))
    assigns = assign(assigns, :sort_field, current_sort_field(assigns.sort))

    ~H"""
    <div class="sm:px-6 lg:px-8 px-4">
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
                    <%= if col[:sort] do %>
                      <span
                        class="group inline-flex cursor-pointer select-none"
                        phx-click="sort:select"
                        phx-value-sort={col[:field]}
                      >
                        <span :if={col[:align] != "right"}><%= col[:label] %></span>
                        <span class={[
                          "flex-none rounded text-gray-400 dark:text-gray-500",
                          col[:align] == "right" && "mr-2",
                          col[:align] != "right" && "ml-2",
                          @sort_field != col[:field] &&
                            "invisible group-hover:visible group-focus:visible",
                          @sort_field == col[:field] &&
                            "rounded bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-white group-hover:bg-gray-200 dark:group-hover:bg-gray-700"
                        ]}>
                          <svg
                            :if={@sort_dir == "asc"}
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            class="w-5 h-5"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z"
                              clip-rule="evenodd"
                            />
                          </svg>
                          <svg
                            :if={@sort_dir == "desc"}
                            class="w-5 h-5"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                              clip-rule="evenodd"
                            >
                            </path>
                          </svg>
                        </span>
                        <span :if={col[:align] == "right"}><%= col[:label] %></span>
                      </span>
                    <% else %>
                      <%= col[:label] %>
                    <% end %>
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
                  class={[
                    "group",
                    row_selected(row) &&
                      "bg-gray-500/5 dark:bg-gray-400/10",
                    !row_selected(row) && "dark:hover:bg-black/10 hover:bg-gray-400/10"
                  ]}
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

  # Private function to determine if the row is selected
  defp row_selected({_id, row}) when is_map(row) do
    row
    |> Map.has_key?(:selected) && row.selected == true
  end

  defp row_selected({_id, _row}) do
    false
  end
end
