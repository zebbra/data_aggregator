defmodule DataAggregatorWeb.CollectionLive.Components do
  @moduledoc false
  use DataAggregatorWeb, :html

  attr :href, :string, required: true
  attr :title, :string, required: true
  attr :value, :float, required: true
  attr :desc, :integer, required: true
  attr :active, :boolean, default: false

  def scope_stat(assigns) do
    ~H"""
    <.link
      patch={@href}
      class={[
        "lg:stat btn btn-outline lg:text-left lg:h-auto group",
        @active && "btn-primary lg:border-primary",
        @active == false && "border-base-content/20 lg:border-base-content/20"
      ]}
    >
      <div class={[
        "truncate leading-4 lg:stat-title",
        @active && "lg:text-primary/75 lg:group-hover:text-primary-content",
        @active == false && "lg:group-hover:text-base-100/80"
      ]}>
        <%= @title %>
      </div>
      <div class={["stat-value max-lg:hidden"]}><%= format_percent(@value) %></div>
      <div class={[
        "stat-desc max-lg:hidden",
        @active && "lg:text-primary/75 lg:group-hover:text-primary-content",
        @active == false && "lg:group-hover:text-base-100/80"
      ]}>
        <%= format_number(@desc) %>
      </div>
    </.link>
    """
  end
end
