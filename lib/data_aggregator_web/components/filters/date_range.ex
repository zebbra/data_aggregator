defmodule DataAggregatorWeb.Filters.DateRange do
  @moduledoc """
  This module provides a date range filter.

  You can pass a list of presets to the filter, which will be displayed as
  quick links to the user. The presets are tuples with a label and a `shift_date_unites`.

  ## Example

  ```heex
  <.date_range
    component={@component}
    title={~t"Date"m}
    description={~t"Search your records by occurrence date"m}
    min_date={Cldr.Calendar.date_from_tuple({1800, 1, 1})}
    max_date={Cldr.Calendar.current(Date.utc_today(), :day)}
    presets={[
      months: ~t"Last Month"m,
      years: ~t"Last Year"m,
      century: ~t"Last Century"m
    ]}
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

  alias Pagify.FilterForm

  attr :title, :string,
    required: true,
    doc: "The label of the date range filter"

  attr :description, :string,
    default: nil,
    doc: "The optional description of the date range filter"

  attr :component, :map,
    required: true,
    doc: "FilterForm (group) which holds the date range components"

  attr :min_date, Date,
    default: nil,
    doc: "The optional minimum date for the date range filter"

  attr :max_date, Date,
    default: nil,
    doc: "The optional maximum date for the date range filter"

  attr :presets, :list, default: [], doc: "A list of presets for the date range filter"

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

  def date_range(%{component: %{source: %FilterForm{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        <%= @title %>
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />
        <:subtitle :if={@description}>
          <%= @description %>
        </:subtitle>
      </.section_heading>
      <.fieldgroup class="flex flex-col gap-4">
        <div
          :if={Enum.any?(@presets)}
          class="ps-6 max-w-[100vw] no-scrollbar -mx-6 -mt-4 flex overflow-auto sm:max-w-3xl"
        >
          <span
            :for={{preset, label} <- @presets}
            phx-click="filter_group:preset"
            phx-value-key={@component.source.key}
            phx-value-preset={preset}
            phx-target={@target}
            class="bg-base-200 mr-2.5 inline-block cursor-pointer whitespace-nowrap rounded px-2 py-1 text-sm hover:bg-base-300"
          >
            <%= label %>
          </span>
        </div>
        <div class="flex flex-col gap-4 sm:flex-row">
          <.inputs_for :let={component} field={@component[:components]}>
            <.input type="hidden" field={component[:field]} />
            <.input type="hidden" field={component[:operator]} />
            <.input type="hidden" field={component[:path]} />
            <.field
              type="date"
              field={component[:value]}
              min={@min_date && Date.to_string(@min_date)}
              max={@max_date && Date.to_string(@max_date)}
              phx-debounce="300"
            />
          </.inputs_for>
        </div>
      </.fieldgroup>
    </.fieldset>
    """
  end
end
