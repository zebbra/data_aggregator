defmodule DataAggregatorWeb.Filters.ClearLink do
  @moduledoc """
  This module provides a clear link for filters.

  It triggers either the `filter_predicate:reset` or the
  `filter_group:reset` event, depending on the type of the filter.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  alias AshPagify.FilterForm
  alias AshPhoenix.FilterForm.Predicate

  attr :component, :map, required: true, doc: "Could be a FilterForm (group) or a Predicate"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  def clear_link(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <span
      class="link link-primary link-hover text-sm/4 pl-2 font-semibold"
      phx-click="filter_predicate:reset"
      phx-value-predicate-id={@component.source.id}
      phx-target={@target}
    >
      {~t"Clear"m}
    </span>
    """
  end

  def clear_link(%{component: %{source: %FilterForm{}}} = assigns) do
    ~H"""
    <span
      class="link link-primary link-hover text-sm/4 pl-2 font-semibold"
      phx-click="filter_group:reset"
      phx-value-key={@component.source.key}
      phx-target={@target}
    >
      {~t"Clear"m}
    </span>
    """
  end
end
