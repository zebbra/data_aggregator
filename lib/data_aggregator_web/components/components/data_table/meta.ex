defmodule DataAggregatorWeb.Components.DataTable.Meta do
  @moduledoc false
  defstruct count: nil, limit: 15, offset: 0, sort: nil, filter: nil, more?: false

  def create_meta_from_data(%Ash.Page.Offset{count: count, limit: limit, offset: offset, more?: more?, rerun: rerun}) do
    %__MODULE__{
      count: count,
      limit: limit,
      offset: offset,
      sort: rerun |> elem(0) |> Map.get(:sort) |> List.first(),
      more?: more?
    }
  end

  def add_filters_from_params(meta, params) do
    case params do
      %{"filter" => filter} ->
        Map.put(meta, :filter, filter)

      _ ->
        meta
    end
  end
end
