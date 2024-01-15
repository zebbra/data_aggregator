defmodule DataAggregatorWeb.Components.Internal.Sort do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  # Assign the current sort from URL params to the socket
  def assign_current_sort(socket, params) do
    sort =
      case params do
        %{"sort" => sort} -> sort
        _ -> ""
      end

    validate_sort_field(sort)

    assign(socket, :current_sort, sort)
  end

  # Extract the sort field from current_sort
  def current_sort_field(current_sort) when is_nil(current_sort), do: ""

  def current_sort_field(current_sort) do
    String.replace(current_sort, "-", "")
  end

  # Extract the sort direction from current_sort
  def current_sort_dir(current_sort) when is_nil(current_sort), do: "asc"

  def current_sort_dir(current_sort) do
    if String.starts_with?(current_sort, "-") do
      "desc"
    else
      "asc"
    end
  end

  # Handle a sort event from the client
  def handle_sort(socket, sort) do
    %{current_sort: current_sort} = socket.assigns

    sort =
      case current_sort do
        # toggle desc -> asc
        "-" <> ^sort -> sort
        # toggle asc -> desc
        ^sort -> "-" <> sort
        # default to desc for new sort
        _ -> "-" <> sort
      end

    socket
    |> assign(:current_sort, sort)
    |> assign(:current_selected, nil)
  end

  # Prevent random atoms from being created from user input
  defp validate_sort_field(sort) do
    sort
    |> String.replace("-", "")
    |> String.to_existing_atom()
  end

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Components.Internal.Sort

      @impl true
      def handle_event("sort:select", %{"sort" => sort}, socket) do
        socket = handle_sort(socket, sort)

        {:noreply,
         patch_params(socket, %{
           sort: socket.assigns.current_sort,
           limit: socket.assigns.current_limit
         })}
      end
    end
  end
end
