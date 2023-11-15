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
    <div class="dark:bg-gray-900 sm:p-6 dark:border-gray-600 px-4 py-5 overflow-hidden bg-white border border-indigo-400 rounded-lg shadow">
      <dt class="text-sm font-medium text-gray-500 truncate">
        <%= @label %><%= @label_suffix %>
      </dt>
      <dd class="dark:text-gray-200 mt-1 text-3xl font-semibold tracking-tight text-gray-700">
        <%= @stat %><%= @stat_suffix %>
      </dd>
    </div>
    """
  end
end
