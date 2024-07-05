defmodule DataAggregatorWeb.Filters.TextSearch do
  @moduledoc """
  This module provides a text search filter.

  ## Example

  ```heex
  <.text_search
    component={@component}
    title={~t"Scientific Name"m}
    description={~t"Search your records by scientifc name"m}
    target={@target}
    legend_size="md"
  />
  ```
  """
  use Phoenix.Component

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.Field, only: [field: 1]
  import DataAggregatorWeb.Components.Form, only: [fieldset: 1, fieldgroup: 1]
  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Filters.ClearLink, only: [clear_link: 1]
  import DataAggregatorWeb.Filters.Helpers, only: [present?: 1]

  alias AshPhoenix.FilterForm.Predicate

  attr :title, :string,
    required: true,
    doc: "The label of the radio group"

  attr :description, :string,
    default: nil,
    doc: "The optional description of the radio group filter"

  attr :component, :map,
    required: true,
    doc: "Predicate which holds the information for the radio group"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  attr :legend_size, :string,
    default: "xl",
    values: ~w(sm md lg xl 2xl),
    doc: "The size of the legend"

  attr :top_level, :boolean,
    default: false,
    doc: "Whether this is a top-level filter (for spacing and borders)"

  def text_search(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        <%= @title %>
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />
        <:subtitle :if={@description}>
          <%= @description %>
        </:subtitle>
      </.section_heading>
      <.fieldgroup class={@top_level == false && "!mt-4 mb-4"}>
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.field field={@component[:value]} class="w-full" phx-debounce="300" />
      </.fieldgroup>
    </.fieldset>
    """
  end
end
