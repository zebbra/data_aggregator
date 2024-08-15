defmodule DataAggregatorWeb.Filters.CheckboxGroup do
  @moduledoc """
  This module provides a checkbox group filter.

  ## Example

  ```heex
  <.checkbox_group
    component={@component}
    title={~t"Continent"m}
    target={@target}
    options={@distinct_options[:loc_continent]}
    legend_size="md"
  />
  ```
  """
  use Phoenix.Component

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]

  import DataAggregatorWeb.Components.Field,
    only: [errors: 1, description: 1, label: 1, translate_error: 1]

  import DataAggregatorWeb.Components.Form, only: [fieldset: 1, fieldgroup: 1]
  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Filters.ClearLink, only: [clear_link: 1]
  import DataAggregatorWeb.Filters.Helpers, only: [present?: 1, options_for_group: 1, checked?: 2]
  import DataAggregatorWeb.Gettext

  alias AshPhoenix.FilterForm.Predicate
  alias Phoenix.HTML.FormField

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

  def checkbox_group(%{component: %{source: %Predicate{}}} = assigns) do
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
        <.checkbox_group_field field={@component[:value]} multiple options={@options} />
      </.fieldgroup>
    </.fieldset>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"

  attr :rest, :global

  slot :inner_block
  slot :custom_label, doc: "the slot for the label text (if you need to customize it)"

  def checkbox_group_field(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> checkbox_group_field()
  end

  def checkbox_group_field(assigns) do
    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} {@rest} />
      <% end %>
      <.input type="hidden" name={@name} value="" disabled={@rest[:disabled]} />
      <.description :if={@description} description={@description} class="mb-2" />
      <.description :if={length(@options) == 0} description={~t"No entries found"m} class="mb-2" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mb-2"} />
      <div class="grid grid-flow-row sm:grid-cols-2 sm:gap-x-2">
        <div
          :for={{label, value} <- options_for_group(@options)}
          class="flex cursor-pointer justify-between gap-4 truncate py-2 sm:flex-row-reverse sm:justify-end"
        >
          <.label for={"#{@name}-#{value}"} label={label} class="cursor-pointer min-w-0 flex-1" />
          <input
            type="checkbox"
            id={"#{@name}-#{value}"}
            name={@name}
            value={value}
            checked={checked?(value, @value)}
            class="checkbox"
            {@rest}
          />
        </div>
      </div>
    </div>
    """
  end
end
