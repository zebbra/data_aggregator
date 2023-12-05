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
    <div class="overflow-x-auto">
      <table role="table" class="table">
        <thead role="rowgroup">
          <tr role="row">
            <th :for={col <- @col} role="columnheader" scope="col">
              <%= col[:label] %>
            </th>
            <th :if={@action != []} role="columnheader" scope="col">
              <span class="sr-only"><%= ~t"Actions"m %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          role="rowgroup"
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        >
          <tr :for={row <- @rows} role="rowgroup" id={@row_id && @row_id.(row)}>
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              role="cell"
              class={[@row_click && "hover:cursor-pointer"]}
            >
              <%= render_slot(col, @row_item.(row)) %>
            </td>
            <td :if={@action != []} role="cell" class="whitespace-nowrap text-right">
              <span :for={action <- @action} class="">
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
