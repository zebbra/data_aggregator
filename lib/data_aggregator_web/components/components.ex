defmodule DataAggregatorWeb.Components do
  @moduledoc """
  This module is used to import all components, blocks, and live_components at once.
  """

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Components.{
        Alert,
        Drawer,
        Dropdown,
        Flash,
        Form,
        Icon,
        Input,
        List,
        LocaleSelect,
        Modal,
        Progress,
        Table,
        Transitions
      }

      use DataAggregatorWeb.LiveComponents.ThemeSelect
    end
  end
end
