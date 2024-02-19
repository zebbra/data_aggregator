defmodule DataAggregatorWeb.Blocks.EmptyState do
  @moduledoc """
  This module contains the empty state block.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]

  attr :title, :string, default: ~t"No entries"m
  attr :description, :string, default: ~t"Get started by creating a new entry."m
  attr :label, :string, default: ~t"New entry"m
  attr :icon, :string, default: "hero-folder"
  attr :href, :string, required: true

  def empty_state(assigns) do
    ~H"""
    <div class="flex h-64 items-center justify-center">
      <div class="text-center">
        <.icon name={@icon} class="text-base-content/50" />
        <h3 class="text-base-content mt-2 text-sm font-semibold"><%= @title %></h3>
        <p class="text-base-content/50 mt-1 text-sm"><%= @description %></p>
        <div class="mt-6">
          <.link navigate={@href} type="button" class="btn btn-primary btn-sm">
            <.icon name="hero-plus-mini" />
            <%= @label %>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
