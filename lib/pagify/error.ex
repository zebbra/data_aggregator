defmodule Pagify.Error do
  @moduledoc false
  def clear_stacktrace(data) when is_list(data) do
    Enum.map(data, &clear_stacktrace/1)
  end

  def clear_stacktrace(%{stacktrace: _} = item) do
    Map.update!(item, :stacktrace, fn _ -> nil end)
  end

  def clear_stacktrace(item) when is_map(item) do
    Enum.map(item, &clear_stacktrace/1)
  end

  def clear_stacktrace({key, errors}) do
    {key, clear_stacktrace(errors)}
  end

  def clear_stacktrace(item) do
    item
  end
end

defmodule Pagify.Error.InvalidParamsError do
  @moduledoc """
  Raised when parameter validation fails.

  This can occur under a number of circumstances, such as:

  - Pagination parameters are improperly formatted or invalid.
  - Filter values are incompatible with the respective field's type or specified
    operator.
  - Ordering parameters are not provided in the correct format.
  """

  @type t :: %__MODULE__{
          errors: keyword,
          params: map
        }

  defexception [:errors, :params]

  def message(%{errors: errors, params: params}) do
    """
    invalid Pagify parameters

    The parameters provided to Pagify:

    #{format(params)}

    Resulted in the following validation errors:

    #{format(errors)}
    """
  end

  defp format(s) do
    s
    |> inspect(pretty: true)
    |> String.split("\n")
    |> Enum.map_join("\n", fn s -> "    " <> s end)
  end
end

defmodule Pagify.Error.InvalidDirectionsError do
  @moduledoc """
  An error that is raised when invalid directions are passed.
  """

  defexception [:directions]

  def message(%{directions: directions}) do
    """
    invalid `:directions` option

    Expected: A 2-tuple of order directions, e.g. `{:asc, :desc}`.

    Received: #{inspect(directions)}"

    The valid order directions are:

    - :asc
    - :asc_nils_first
    - :desc
    - :desc_nils_last
    """
  end
end

defmodule Pagify.Error.Query.InvalidOrderByParameter do
  @moduledoc "Used when an invalid order_by is provided"
  use Ash.Error.Exception
  use Splode.Error, fields: [:order_by], class: :invalid

  def message(%{order_by: order_by}) do
    "#{inspect(order_by)} is not a valid order_by parameter"
  end
end

defmodule Pagify.Error.Query.InvalidScopesParameter do
  @moduledoc "Used when an invalid scopes is provided"
  use Ash.Error.Exception
  use Splode.Error, fields: [:scopes], class: :invalid

  def message(%{scopes: scopes}) do
    "#{inspect(scopes)} is not a valid scopes parameter"
  end
end

defmodule Pagify.Error.Query.NoSuchScope do
  @moduledoc "Used when an invalid scopes is provided"
  use Ash.Error.Exception
  use Splode.Error, fields: [:group, :name], class: :invalid

  def message(%{group: group, name: name}) do
    "#{inspect(name)} is not a valid scope parameter for group #{inspect(group)}"
  end
end

defmodule Pagify.Error.Components.PathOrJSError do
  @moduledoc """
  Raised when a neither the `path` nor the `on_*` attribute is set for a
  pagination or table component.
  """
  defexception [:component]

  def message(%{component: component}) do
    """
    path or #{on_attribute(component)} attribute is required

    At least one of the mentioned attributes is required for the #{component}
    component. Combining them will both patch the URL and execute the
    JS command.

    The :path value can be a path as a string, a {module, function_name, args}
    tuple, a {function, args} tuple, or an 1-ary function.

    Examples:

        path={~p"/posts"}
        path={{Routes, :post_path, [@socket, :index]}}
        path={{&Routes.post_path/3, [@socket, :index]}}
        path={&build_path/1}

        #{on_examples(component)}
    """
  end

  defp on_attribute(:table), do: "on_sort"
  defp on_attribute(_), do: "on_paginate"

  defp on_examples(:table), do: "on_sort={JS.push(\"sort-table\")}"
  defp on_examples(_), do: "on_paginate={JS.push(\"paginate\")}"
end
