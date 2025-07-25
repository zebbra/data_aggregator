defmodule DataAggregatorWeb.Filters.CheckboxGroupFilter do
  @moduledoc """
  This module provides a checkbox group filter.

  ## Example

  ```heex
  <.checkbox_group_filter
    component={@component}
    title={~t"Continent"m}
    target={@target}
    options={@distinct_options[:loc_continent]}
    legend_size="md"
  />
  ```
  """
  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.FieldGroup, only: [checkbox_group: 1]
  import DataAggregatorWeb.Components.Form, only: [fieldset: 1, fieldgroup: 1]
  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Filters.ClearLink, only: [clear_link: 1]
  import DataAggregatorWeb.Filters.Helpers, only: [present?: 1]

  alias AshPhoenix.FilterForm.Predicate

  attr :title, :string,
    required: true,
    doc: "The label of the checkbox group"

  attr :description, :string,
    default: nil,
    doc: "The optional description of the checkbox group filter"

  attr :component, :map,
    required: true,
    doc: "Predicate which holds the information for the checkbox group"

  attr :options, :list,
    default: [],
    doc: "The list of options for the checkbox group"

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

  def checkbox_group_filter(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        {@title}
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />
        <:subtitle :if={@description}>
          {@description}
        </:subtitle>
      </.section_heading>
      <.fieldgroup class="!mt-3">
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.checkbox_group field={@component[:value]} multiple options={@options} />
      </.fieldgroup>
    </.fieldset>
    """
  end
end
