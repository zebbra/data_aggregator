defmodule DataAggregatorWeb.Components do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use DataAggregatorWeb.Components.ThemeSelect

      import DataAggregatorWeb.Components.Button
      import DataAggregatorWeb.Components.Datatable
      import DataAggregatorWeb.Components.Flash
      import DataAggregatorWeb.Components.Form
      import DataAggregatorWeb.Components.Header
      import DataAggregatorWeb.Components.Icon
      import DataAggregatorWeb.Components.List
      import DataAggregatorWeb.Components.Loading
      import DataAggregatorWeb.Components.Menu
      import DataAggregatorWeb.Components.Modal
      import DataAggregatorWeb.Components.Pagination
      import DataAggregatorWeb.Components.Progress
      import DataAggregatorWeb.Components.Sidebar
      import DataAggregatorWeb.Components.SlideOver
      import DataAggregatorWeb.Components.StatCard
      import DataAggregatorWeb.Components.Switch
      import DataAggregatorWeb.Components.Table
      import DataAggregatorWeb.Components.Transitions
    end
  end
end
