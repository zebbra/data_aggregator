defmodule DataAggregatorWeb.Filters.IntegerRange do
  @moduledoc """
  This module provides an integer range filter.

  ## Example

  ```heex
  <.integer_range
    component={@component}
    title={~t"Year"m}
    description={~t"Search your records within a range of years"m}
    min_int={1970}
    max_int={Cldr.Calendar.current(Date.utc_today(), :year)}
    target={@target}
    top_level
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

  alias AshPagify.FilterForm

  attr :title, :string,
    required: true,
    doc: "The label of the integer range filter"

  attr :description, :string,
    default: nil,
    doc: "The optional description of the integer range filter"

  attr :component, :map,
    required: true,
    doc: "FilterForm (group) which holds the integer range components"

  attr :min_int, :integer,
    default: nil,
    doc: "The optional minimum integer for the integer range filter"

  attr :max_int, :integer,
    default: nil,
    doc: "The optional maximum integer for the integer range filter"

  attr :step, :integer,
    default: 1,
    doc: "The step value for the integer range filter"

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

  def integer_range(%{component: %{source: %FilterForm{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        {@title}
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />
        <:subtitle :if={@description}>
          {@description}
        </:subtitle>
      </.section_heading>
      <.fieldgroup>
        <div class="flex flex-col gap-4 sm:flex-row">
          <.inputs_for :let={component} field={@component[:components]}>
            <.input type="hidden" field={component[:field]} />
            <.input type="hidden" field={component[:operator]} />
            <.input type="hidden" field={component[:path]} />
            <.field
              type="number"
              field={component[:value]}
              min={@min_int}
              max={@max_int}
              step={@step}
              phx-debounce="300"
            />
          </.inputs_for>
        </div>
      </.fieldgroup>
    </.fieldset>
    """
  end
end
