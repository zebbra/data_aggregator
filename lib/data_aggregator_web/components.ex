defmodule DataAggregatorWeb.Components do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Components.{
        Button,
        Datatable,
        Icon,
        Flash,
        Form,
        Header,
        List,
        Menu,
        Modal,
        Loading,
        Pagination,
        Progress,
        Sidebar,
        SlideOver,
        StatCard,
        Switch,
        Table,
        Transitions
      }

      use DataAggregatorWeb.Components.ThemeSelect
    end
  end
end
