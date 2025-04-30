defmodule DataAggregatorWeb.CollectionLive.Helpers do
  @moduledoc """
  This module contains helper functions for the collection live view.
  """

  use DataAggregatorWeb.Gettext
  use Phoenix.LiveComponent

  import DataAggregatorWeb.Helpers, only: [get_actor: 1]

  alias DataAggregator.Records.Collection

  def load do
    [
      :digitizing_progress,
      :importing,
      :mapping,
      :exporting,
      :encoding,
      :publishing,
      :validating,
      :deleting,
      :busy
    ]
  end

  @load_light [
    :importing,
    :mapping,
    :exporting,
    :encoding,
    :publishing,
    :validating,
    :deleting,
    :busy
  ]

  def get_collection_light(id, actor) do
    Collection.get_by_id!(id, load: @load_light, actor: actor)
  end

  def busy_action("set_importing"), do: "dataset:import"
  def busy_action(%{importing: true}), do: "dataset:import"
  def busy_action("set_mapping"), do: "collection:mapping"
  def busy_action(%{mapping: true}), do: "collection:mapping"
  def busy_action("set_exporting"), do: "collection:export"
  def busy_action(%{exporting: true}), do: "collection:export"
  def busy_action("set_encoding"), do: "encode:toggle"
  def busy_action(%{encoding: true}), do: "encode:toggle"
  def busy_action("set_publishing"), do: "publication:toggle"
  def busy_action(%{publishing: true}), do: "publication:toggle"
  def busy_action("set_validating"), do: "validation:toggle"
  def busy_action(%{validating: true}), do: "validation:toggle"
  def busy_action(%{deleting: true}), do: "collection:delete"
  def busy_action(_), do: nil

  def busy_action_translation(busy_action) do
    case busy_action do
      "dataset:import" -> ~t"Cancel import"m
      "collection:mapping" -> ~t"Cancel image mapping"m
      "collection:export" -> ~t"Cancel export"m
      "encode:toggle" -> ~t"Cancel encoding"m
      "publication:toggle" -> ~t"Cancel publication"m
      "validation:toggle" -> ~t"Cancel validation"m
      _ -> ~t"Cancel"m
    end
  end

  def state_translation(state) do
    case state do
      :importing -> ~t"Cancel import"m
      :mapping -> ~t"Cancel image mapping"m
      :exporting -> ~t"Cancel export"m
      :encoding -> ~t"Cancel encoding"m
      :pubishing -> ~t"Cancel publication"m
      :validating -> ~t"Cancel validation"m
      _ -> ~t"Cancel"m
    end
  end

  def cancel_action(id, socket, opts \\ []) do
    load = Keyword.get(opts, :load, @load_light)
    collection = Collection.get_by_id!(id, load: load, actor: get_actor(socket))
    action = collection.state

    case Collection.cancel_action(collection, actor: get_actor(socket)) do
      {:ok, _collection} ->
        {:noreply, put_flash(socket, :info, mgettext("Action %{action} cancelled", action: action))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, Ash.Error.error_descriptions(reason))}
    end
  end
end
