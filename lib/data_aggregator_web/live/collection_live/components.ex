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
        "stat cursor-pointer rounded-md border max-lg:text-sm max-lg:px-3 max-lg:py-1.5",
        @active && "bg-primary/10 text-primary border-primary/20",
        @active == false && "border-black-white/10 hover:bg-base-content/10"
      ]}
    >
      <div class={["stat-title truncate", @active && "text-primary/75"]}><%= @title %></div>
      <div class={["stat-value max-lg:hidden"]}><%= format_percent(@value) %></div>
      <div class={["stat-desc max-lg:hidden", @active && "text-primary/75"]}>
        <%= format_number(@desc) %>
      </div>
    </.link>
    """
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Components
    end
  end
end
