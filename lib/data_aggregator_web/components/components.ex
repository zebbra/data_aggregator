defmodule DataAggregatorWeb.Components do
  @moduledoc """
  This module is used to import all components, blocks, and live_components at once.
  """

  defmacro __using__(_) do
    quote do
      use DataAggregatorWeb.LiveComponents.ThemeSelect

      import DataAggregatorWeb.Components.Alert
      import DataAggregatorWeb.Components.Badge
      import DataAggregatorWeb.Components.Breadcrumbs
      import DataAggregatorWeb.Components.Combobox
      import DataAggregatorWeb.Components.Drawer
      import DataAggregatorWeb.Components.Dropdown
      import DataAggregatorWeb.Components.Field
      import DataAggregatorWeb.Components.Flash
      import DataAggregatorWeb.Components.Form
      import DataAggregatorWeb.Components.Icon
      import DataAggregatorWeb.Components.Input
      import DataAggregatorWeb.Components.List
      import DataAggregatorWeb.Components.LocaleSelect
      import DataAggregatorWeb.Components.Modal
      import DataAggregatorWeb.Components.Progress
      import DataAggregatorWeb.Components.Table
      import DataAggregatorWeb.Components.Transitions
    end
  end
end
