defmodule DataAggregatorWeb.Filters.ComboboxGroup do
  @moduledoc """
  This module provides a combobox group filter.

  ## Example

  ```heex
  <.combobox_group
    component={@component}
    title={~t"Continent"m}
    target={@target}
    options={@distinct_options[:loc_continent]}
    legend_size="md"
    multiple
    dropup
  />
  ```
  """
  use Phoenix.Component

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.Form, only: [fieldset: 1, fieldgroup: 1]
  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Filters.ClearLink, only: [clear_link: 1]
  import DataAggregatorWeb.Filters.Helpers, only: [present?: 1]

  alias AshPhoenix.FilterForm.Predicate

  attr :title, :string,
    required: true,
    doc: "The label of the combobox"

  attr :description, :string,
    default: nil,
    doc: "The optional description of the combobox filter"

  attr :component, :map,
    required: true,
    doc: "Predicate which holds the information for the combobox"

  attr :options, :list,
    default: [],
    doc: "The list of options for the combobox"

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

  attr :rest, :global,
    include: ~w(class prompt placeholder multiple create
                max_items max_options tom_select_plugins remote_options_event_name
                remove_button_title remove_button dropup no_results_text
                tom_select_options tom_select_options_global_variable),
    doc: "Additional attributes for the combobox (see `Combobox` component for more details)"

  def combobox_group(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        <%= @title %>
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />
        <:subtitle :if={@description}>
          <%= @description %>
        </:subtitle>
      </.section_heading>
      <.fieldgroup class="!mt-3">
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.input type="combobox" field={@component[:value]} options={@options} {@rest} />
      </.fieldgroup>
    </.fieldset>
    """
  end
end
