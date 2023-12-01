defmodule DataAggregatorWeb.Components.StatCard do
  @moduledoc """
  Card to show a stat and a label
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a Card containing a stat and a label
  """

  attr :label, :string, required: true
  attr :label_suffix, :string, default: ""
  attr :stat, :string, required: true
  attr :stat_suffix, :string, default: ""

  def stat_card(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-indigo-400 bg-white px-4 py-5 shadow dark:border-gray-600 dark:bg-gray-900 sm:p-6">
      <dt class="truncate text-sm font-medium text-gray-500">
        <%= @label %><%= @label_suffix %>
      </dt>
      <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-700 dark:text-gray-200">
        <%= @stat %><%= @stat_suffix %>
      </dd>
    </div>
    """
  end
end
