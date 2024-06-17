defmodule DataAggregatorWeb.Blocks.EmptyState do
  @moduledoc """
  This module contains the empty state block.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Gettext

  @doc """
  Renders an empty state block.

  Used to display an empty state with a title, description, and a button to navigate to a new entry.

  ## Example

  ```heex
  <.empty_state
    title: "No entries",
    description: "Get started by creating a new entry.",
    label: "New entry",
    icon: "hero-folder",
    href: ~p"/entries/new"
  />
  ```
  """
  attr :title, :string, default: ~t"No entries"m, doc: "The title to display in the empty state."

  attr :description, :string,
    default: ~t"Get started by creating a new entry."m,
    doc: "The description to display in the empty state."

  attr :label, :string,
    default: ~t"New entry"m,
    doc: "The label to display in the empty state button."

  attr :icon, :string,
    default: "hero-folder",
    doc: "The icon to display in the empty state button."

  attr :href, :string,
    default: nil,
    doc: """
    The URL to navigate to when the button is clicked.
    If left empty, the button will not be displayed.
    """

  def empty_state(assigns) do
    ~H"""
    <div class="flex h-64 items-center justify-center">
      <div class="text-center">
        <.icon name={@icon} class="text-base-content/50" />
        <h3 class="text-base-content mt-2 text-sm font-semibold"><%= @title %></h3>
        <p class="text-base-content/60 mt-1 text-sm"><%= @description %></p>
        <div :if={@href} class="mt-6">
          <.link navigate={@href} type="button" class="btn btn-primary max-sm:btn-sm">
            <.icon name="hero-plus-mini" />
            <%= @label %>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
