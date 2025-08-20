defmodule DataAggregatorWeb.Filters.RadioGroupFilter do
  @moduledoc """
  This module provides a radio group filter.

  ## Example

  ```heex
  <.radio_group_filter
    component={@component}
    title={~t"IUCN Red List"m}
    description={~t"Search your records by IUCN Red List of Threatened Speciese"m}
    target={@target}
    options={[
      [key: ~t"Any"m, value: ""],
      [key: ~t"Threatened"m, value: "threatened"],
      [key: ~t"Less threatened"m, value: "less_threatened"],
      [key: ~t"Extinct (or nearly)"m, value: "extinct"],
      [key: ~t"Uncertain data"m, value: "uncertain_data"]
    ]}
    top_level
  />
  ```
  """
  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.FieldGroup, only: [radio_group: 1]
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

  attr :option_descriptions, :map,
    default: %{},
    doc: "Custom descriptions for the options"

  attr :component, :map,
    required: true,
    doc: "Predicate which holds the information for the radio group"

  attr :options, :list,
    default: [],
    doc: "The list of options for the radio group"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  attr :legend_size, :string,
    default: "xl",
    values: ~w(sm md lg xl 2xl),
    doc: "The size of the legend"

  attr :pills, :boolean,
    default: false,
    doc: "Whether to render the radio group as pills"

  attr :top_level, :boolean,
    default: false,
    doc: "Whether this is a top-level filter (for spacing and borders)"

  def radio_group_filter(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        {@title}
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />

        <:subtitle :if={description?(@description, @option_descriptions, @component.source.value)}>
          {Map.get(@option_descriptions, @component.source.value, @description)}
        </:subtitle>
      </.section_heading>
      <.fieldgroup class={@pills == false && "sm:px-8"}>
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.radio_group field={@component[:value]} options={@options} pills={@pills} />
      </.fieldgroup>
    </.fieldset>
    """
  end

  defp description?(description, option_descriptions, value) do
    Map.has_key?(option_descriptions, value) || present?(description)
  end
end
