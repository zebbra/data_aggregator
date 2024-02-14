defmodule Storybook.Components.Form.Fieldset do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Form.fieldset/1

  def imports,
    do: [
      {Components.Form,
       [
         simple_form: 1,
         fieldgroup: 1
       ]},
      {Components.Field,
       [
         field: 1,
         label: 1,
         description: 1,
         errors: 1,
         custom_field: 1
       ]},
      {Components.Input, [input: 1]}
    ]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.psb-variation/>
    </.simple_form>
    """
  end

  def variations do
    [
      %Variation{
        id: :basic_example,
        attributes: %{
          legend: "Shipping details",
          text: "Without this your odds of getting your order are low."
        },
        slots: [default_form_content("1")]
      },
      %Variation{
        id: :without_legend,
        attributes: %{
          "aria-label": "Shipping details"
        },
        slots: [default_form_content("2")]
      },
      %Variation{
        id: :with_grid_layout,
        attributes: %{
          legend: "Shipping details",
          text: "Without this your odds of getting your order are low."
        },
        slots: [grid_form_content("1")]
      },
      %Variation{
        id: :with_inline_layout,
        attributes: %{
          legend: "Shipping details",
          text: "Without this your odds of getting your order are low."
        },
        slots: [inline_form_content("2")]
      },
      %Variation{
        id: :with_custom_field,
        attributes: %{
          legend: "Shipping details",
          text: "Without this your odds of getting your order are low."
        },
        slots: [custom_field_form_content("1")]
      }
    ]
  end

  def default_form_content(postfix) do
    """
    <.fieldgroup>
      <.field field={f[:street_address]} id={"street_address_#{postfix}"} label="Street address" required />
      <.field
        field={f[:country]}
        id={"country_#{postfix}"}
        label="Country"
        description="We currently only ship to North America."
        required
        type="select"
        options={["Canada", "Mexico", "United States"]}
      />
      <.field
        field={f[:notes]}
        id={"notes_#{postfix}"}
        label="Delivery notes"
        description="If you have a tiger, we'd like to know about it."
        type="textarea"
        required
      />
    </.fieldgroup>
    """
  end

  def grid_form_content(postfix) do
    """
    <.fieldgroup>
      <div class="grid grid-cols-1 gap-8 sm:grid-cols-2 sm:gap-4">
        <.field field={f[:first_name]} label="First name" required />
        <.field field={f[:last_name]} label="Last name" required />
      </div>

      <.field field={f[:street_address]} label="Street address" required />
      <div class="grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-4">
        <div class="sm:col-span-2">
          <.field
            field={f[:country]}
            label="Country"
            description="We currently only ship to North America."
            required
            type="select"
            options={["Canada", "Mexico", "United States"]}
          />
        </div>
        <.field field={f[:postal_code]} label="Postal code" required />
      </div>
      <.field
        field={f[:notes]}
        label="Delivery notes"
        description="If you have a tiger, we'd like to know about it."
        type="textarea"
        required
      />
      <.field
        field={f[:checkbox]}
        id={"checkbox_#{postfix}"}
        label="Checkbox input"
        description="Checkbox input description"
        type="checkbox"
        required
      />
      <.field
        field={f[:toggle]}
        id={"toggle_#{postfix}"}
        label="Toggle input"
        description="Toggle input description"
        type="toggle"
        required
      />
    </.fieldgroup>
    <.fieldgroup class="space-y-3">
      <.field
        field={f[:radio_option_1_#{postfix}]}
        name="story[radio_input_#{postfix}]"
        label="Private"
        description="Your data is private and will not be shared with anyone."
        type="radio"
        required
      />
      <.field
        field={f[:radio_option_2_#{postfix}]}
        name="story[radio_input_#{postfix}]"
        label="Public"
        description="Your data is public and will be shared with everyone."
        type="radio"
        required
      />
    </.fieldgroup>
    """
  end

  def inline_form_content(postfix) do
    """
    <.fieldgroup inline>
      <.field inline field={f[:first_name_#{postfix}]} label="First name" required />
      <.field inline field={f[:last_name_#{postfix}]} label="Last name" required />
      <.field inline field={f[:street_address_#{postfix}]} label="Street address" required />
      <.field inline field={f[:country_#{postfix}]} label="Country" description="We currently only ship to North America." required type="select" options={["Canada", "Mexico", "United States"]} />
      <.field inline field={f[:postal_code_#{postfix}]} label="Postal code" required />
      <.field inline field={f[:notes_#{postfix}]} label="Delivery notes" description="If you have a tiger, we'd like to know about it." type="textarea" required />
      <.field inline field={f[:checkbox_#{postfix}]} id={"checkbox_#{postfix}"} label="Checkbox input" description="Checkbox input description" type="checkbox" required />
      <.field inline field={f[:toggle]} id={"toggle_#{postfix}"} label="Toggle input" description="Toggle input description" type="toggle" required />
      <.field inline field={f[:radio_option_1_#{postfix}]} name="story[radio_input_#{postfix}]" label="Private" description="Your data is private and will not be shared with anyone." type="radio" required />
      <.field inline field={f[:radio_option_2_#{postfix}]} name="story[radio_input_#{postfix}]" label="Public" description="Your data is public and will be shared with everyone." type="radio" required />
    </.fieldgroup>
    """
  end

  def custom_field_form_content(postfix) do
    """
    <.fieldgroup class="relative flex items-start">
      <.custom_field field={f[:checkbox_custom]} id={"checkbox_custom_#{postfix}"} type="checkbox">
        <:content :let={field}>
        <div class="flex flex-row">
          <.input {field} />
          <div class="ml-3 flex space-x-2">
            <.label for={field.id} label="Checkbox input" required {field} />
            <.description description="Checkbox input description" {field} />
          </div>
          </div>
          <.errors errors={field.errors} id={field.id} />
        </:content>
      </.custom_field>
    </.fieldgroup>
    """
  end
end
