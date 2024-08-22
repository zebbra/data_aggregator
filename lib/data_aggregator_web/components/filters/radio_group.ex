defmodule DataAggregatorWeb.Filters.RadioGroup do
  @moduledoc """
  This module provides a radio group filter.

  ## Example

  ```heex
  <.radio_group
    component={@component}
    title={~t"IUCN Red List"m}
    description={~t"Search your records by IUCN Red List of Threatened Speciese"m}
    target={@target}
    options={[
      [key: ~t"Any"m, value: ""],
      [key: ~t"Endangered"m, value: "true"],
      [key: ~t"Safe"m, value: "false"]
    ]}
    top_level
  />
  ```
  """
  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]

  import DataAggregatorWeb.Components.Field,
    only: [errors: 1, description: 1, label: 1, translate_error: 1]

  import DataAggregatorWeb.Components.Form, only: [fieldset: 1, fieldgroup: 1]
  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Filters.ClearLink, only: [clear_link: 1]
  import DataAggregatorWeb.Filters.Helpers, only: [present?: 1, options_for_group: 1, checked?: 2]

  alias AshPhoenix.FilterForm.Predicate
  alias Phoenix.HTML.FormField

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

  def radio_group(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.fieldset class={@top_level && "border-black-white/10 border-b py-8"}>
      <.section_heading as="legend" size={@legend_size}>
        <%= @title %>
        <.clear_link :if={present?(@component.source)} component={@component} target={@target} />

        <:subtitle :if={description?(@description, @option_descriptions, @component.source.value)}>
          <%= Map.get(@option_descriptions, @component.source.value, @description) %>
        </:subtitle>
      </.section_heading>
      <.fieldgroup class={@pills == false && "sm:px-8"}>
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.radio_group_field field={@component[:value]} options={@options} pills={@pills} />
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
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"

  attr :pills, :boolean, default: false, doc: "whether to render the radio group as pills"

  attr :rest, :global

  slot :inner_block
  slot :custom_label, doc: "the slot for the label text (if you need to customize it)"

  def radio_group_field(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> radio_group_field()
  end

  def radio_group_field(assigns) do
    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} {@rest} />
      <% end %>
      <.description :if={@description} description={@description} class="mb-2" />
      <.description :if={length(@options) == 0} description={~t"No entries found"m} class="mb-2" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mb-2"} />
      <div class={[
        @pills == true &&
          "ps-6 max-w-[100vw] no-scrollbar -mx-6 -mt-4 flex overflow-auto py-1 sm:max-w-3xl",
        @pills == false && "join grid auto-cols-fr grid-flow-col"
      ]}>
        <input
          :for={{label, value} <- options_for_group(@options)}
          type="radio"
          id={"#{@name}-#{value}"}
          name={@name}
          value={value}
          checked={checked?(value, @value)}
          class={[
            @pills == true &&
              "btn min-h-[auto] min-w-[59px] text-base-content border-base-content/20 leading-[18px] mr-2.5 inline-block h-auto overflow-clip rounded-3xl bg-transparent px-5 py-2.5 text-sm font-normal checked:!bg-base-content checked:!text-base-100 checked:!border-base-content hover:bg-base-100 hover:border-base-content focus-visible:!outline-base-content",
            @pills == false &&
              "join-item btn btn-lg text-base-content border-base-content/20 overflow-clip bg-transparent text-sm font-medium checked:!bg-base-content checked:!text-base-100 checked:!border-base-content hover:bg-base-100 hover:border-base-content focus-visible:!outline-base-content sm:text-base/5"
          ]}
          aria-label={label}
          {@rest}
        />
      </div>
    </div>
    """
  end

  defp description?(description, option_descriptions, value) do
    Map.has_key?(option_descriptions, value) || present?(description)
  end
end
