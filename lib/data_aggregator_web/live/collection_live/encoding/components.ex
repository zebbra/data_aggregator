defmodule DataAggregatorWeb.CollectionLive.Encoding.Components do
  @moduledoc """
  This module contains components for the collection > encoding live view.
  """

  use DataAggregatorWeb, :html

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  @states ~w(encoded success failed encoding queued unchanged incomplete imported)a

  attr(:state, :atom, required: false, values: @states)

  def encoding_state_indicator(assigns) do
    ~H"""
    <div
      class={["tooltip tooltip-right flex-none rounded-full p-1", state_indicator_class(@state)]}
      data-tip={state_translation(@state)}
    >
      <div class="h-2 w-2 rounded-full bg-current" />
    </div>
    """
  end

  attr(:state, :atom, required: false, values: @states)
  attr(:small, :boolean, default: false)
  attr(:reason, :string, default: nil)
  attr(:icon, :string, default: nil)
  attr(:icon_class, :string, default: nil)

  def encoding_state_badge(assigns) do
    {icon, icon_class} = state_badge_icon(assigns.state)

    assigns =
      assigns
      |> assign(:icon, icon)
      |> assign(:icon_class, icon_class)

    ~H"""
    <.badge
      class="tooltip before:text-xs"
      color={state_color(@state)}
      data-tip={state_badge_tooltip(@state, @reason, @small)}
    >
      <.icon name={@icon} class={class_names([@icon_class, "size-5"])} />
      <span :if={!@small} class="truncate pr-1.5"><%= state_translation(@state) %></span>
    </.badge>
    """
  end

  defp state_indicator_class(state) do
    gray = "bg-base-300 text-base-content/60"
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

  defp state_color(state) do
    cond do
      state in [:encoded, :success] -> "green"
      state in [:failed, :error] -> "red"
      state in [:encoding, :queued, :unchanged, :imported, :incomplete] -> "blue"
      true -> "gray"
    end
  end

  defp state_badge_icon(state) do
    cond do
      state in [:encoded, :success] -> {"hero-check-circle-solid", nil}
      state in [:failed, :error] -> {"hero-x-circle-solid", nil}
      state in [:encoding, :queued] -> {"hero-cog-6-tooth-solid", "animate-spin"}
      state in [:unchanged, :imported, :incomplete] -> {"hero-information-circle-solid", nil}
      true -> {"hero-question-mark-circle-solid", nil}
    end
  end

  defp state_badge_tooltip(state, reason, small) do
    cond do
      state in [:failed, :error] -> reason || ~t"Error occured"m
      small -> state_translation(state)
      true -> nil
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp state_translation(state) do
    cond do
      state == :encoded -> ~t"Successful"m
      state == :success -> ~t"Successful"m
      state == :failed -> ~t"Failed"m
      state == :error -> ~t"Failed"m
      state == :encoding -> ~t"Processing"m
      state == :queued -> ~t"Processing"m
      state == :unchanged -> ~t"Unchanged"m
      state == :incomplete -> ~t"Not encoded"m
      state == :imported -> ~t"Not encoded"m
      true -> ~t"Unknown"m
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Encoding.Components
    end
  end
end
