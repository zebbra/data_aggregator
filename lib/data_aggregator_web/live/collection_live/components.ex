defmodule DataAggregatorWeb.CollectionLive.Components do
  @moduledoc """
  This module contains components for the collection live view.
  """

  use DataAggregatorWeb, :html

  alias DataAggregator.Records.Collection

  @states AshStateMachine.Info.state_machine_all_states(Collection)

  attr :collection, Collection, required: false
  attr :state, :atom, required: false, values: @states

  def collection_state_badge(%{collection: collection} = assigns) when is_struct(collection) do
    assigns
    |> assign(:state, collection.state)
    |> assign(:collection, nil)
    |> collection_state_badge()
  end

  def collection_state_badge(assigns) do
    ~H"""
    <.badge class="pr-3" color={state_color(@state)}>
      <.collection_state_icon state={@state} />
      <span>{state_translation(@state)}</span>
    </.badge>
    """
  end

  defp state_color(state) do
    if state == :idle do
      "green"
    else
      "blue"
    end
  end

  attr :state, :atom, required: true, values: @states

  defp collection_state_icon(%{state: state} = assigns) do
    {icon, class} = collection_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp collection_state_icon_class(state) do
    if state == :idle do
      {"hero-clock-solid", "text-base-content opacity-60"}
    else
      {"hero-cog-6-tooth-solid", "text-info animate-spin"}
    end
  end

  defp state_translation(state) do
    case state do
      :mapping -> ~t"Mapping"m
      :importing -> ~t"Importing"m
      :exporting -> ~t"Exporting"m
      :encoding -> ~t"Encoding"m
      :fast_track_publishing -> ~t"Publishing"m
      :approving -> ~t"Approving"m
      :deleting -> ~t"Deleting"m
      _ -> ~t"Ready"m
    end
  end
end
