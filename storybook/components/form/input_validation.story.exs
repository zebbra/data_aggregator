defmodule Storybook.Components.Form.InputValidation do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Input.input/1
  def imports, do: [{Components.Form, [simple_form: 1, fieldgroup: 1]}]

  def template do
    """
    <.simple_form for={%{}} as={:story} class="w-full">
      <.fieldgroup class="flex flex-col space-y-8 form-control">
        <.psb-variation-group field={%Phoenix.HTML.FormField{id: "story_field", name: "story[field]", field: :field, value: nil, errors: ["message", %{}], form: %Phoenix.HTML.Form{source: %{},impl: Phoenix.HTML.FormData.Map,id: "story",name: "story",data: %{},hidden: [],params: %{},errors: [],options: [class: "w-full", multipart: false],index: nil}}} required />
      </.fieldgroup>
    </.simple_form>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :basic_inputs,
        variations:
          for type <-
                ~w(checkbox color date datetime-local email hidden month number password
               range search tel text textarea time url week toggle file)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                label: String.capitalize("#{type} input"),
                autocomplete: to_string(type)
              }
            }
          end
      },
      %VariationGroup{
        id: :radio,
        variations:
          for option <- [:option_1, :option_2, :option_3] do
            %Variation{
              id: option,
              attributes: %{
                label: String.capitalize("#{option} input"),
                type: "radio",
                name: "radio_input"
              }
            }
          end
      },
      %Variation{
        id: :select,
        attributes: %{
          label: "Select input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"]
        }
      },
      %Variation{
        id: :multi_select,
        attributes: %{
          label: "Multiselect input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          multiple: true
        }
      }
    ]
  end
end
