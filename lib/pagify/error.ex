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

defmodule Pagify.Error.Query.InvalidOrderByParameter do
  @moduledoc "Used when an invalid order_by is provided"
  use Ash.Error.Exception
  use Splode.Error, fields: [:order_by], class: :invalid

  def message(%{order_by: order_by}) do
    "#{inspect(order_by)} is not a valid order_by parameter"
  end
end
