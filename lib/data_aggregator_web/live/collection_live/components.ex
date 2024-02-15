defmodule DataAggregatorWeb.CollectionLive.Components do
  use DataAggregatorWeb, :html

  attr(:href, :string, required: true)
  attr(:title, :string, required: true)
  attr(:value, :float, required: true)
  attr(:desc, :integer, required: true)
  attr(:active, :boolean, default: false)

  def scope_stat(assigns) do
    ~H"""
    <.link
      patch={@href}
      class={[
        "stat cursor-pointer rounded-md max-lg:text-sm max-lg:px-3 max-lg:py-1.5",
        @active && "bg-neutral text-neutral-content",
        @active == false && "border border-black-white/10 hover:bg-base-content/10"
      ]}
    >
      <div class={["stat-title truncate", @active && "text-neutral-content"]}><%= @title %></div>
      <div class={["stat-value max-lg:hidden"]}><%= format_percent(@value) %></div>
      <div class={["stat-desc max-lg:hidden", @active && "text-neutral-content"]}>
        <%= format_number(@desc) %>
      </div>
    </.link>
    """
  end

  attr(:state, :atom, default: nil)

  def state_indicator(assigns) do
    ~H"""
    <div
      class={["tooltip tooltip-right flex-none rounded-full p-1", state_indicator_class(@state)]}
      data-tip={state_translation(@state)}
    >
      <div class="h-2 w-2 rounded-full bg-current" />
    </div>
    """
  end

  defp state_indicator_class(state) do
    gray = "bg-neutral_content/50 text-neutral/50"
    blue = "bg-info/10 text-info"
    green = "bg-success/10 text-success"
    red = "bg-error/10 text-error"
    orange = "bg-warning/10 text-warning"

    cond do
      state in [:encoded, :success] -> green
      state in [:failed, :error] -> red
      state in [:encoding, :queued, :unchanged] -> blue
      state in [:incomplete, :imported] -> orange
      true -> gray
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp state_translation(state) do
    cond do
      state == :encoded -> ~t"Encoded"m
      state == :success -> ~t"Success"m
      state == :failed -> ~t"Failed"m
      state == :encoding -> ~t"Encoding"m
      state == :queued -> ~t"Queued"m
      state == :unchanged -> ~t"Unchagned"m
      state == :incomplete -> ~t"Incomplete"m
      state == :imported -> ~t"Imported"m
      true -> ~t"Unknown"m
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Components
    end
  end
end
