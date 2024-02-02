defmodule Storybook.Components.Form.FieldInline do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Form.field/1
  def imports, do: [{Components.Form, [simple_form: 1, fieldgroup: 1]}]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.fieldgroup class="space-y-2" inline>
        <.psb-variation-group field={f[:field]} required inline />
      </.fieldgroup>
    </.simple_form>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :inline_inputs,
        variations:
          for type <-
                ~w(checkbox color date datetime-local email hidden month number password
               range search tel text textarea time url week toggle)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                label: String.capitalize("#{type} input"),
                autocomplete: to_string(type),
                description: String.capitalize("#{type} input description")
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
                name: "radio_input",
                description: "Radio input description"
              }
            }
          end
      },
      %Variation{
        id: :select,
        attributes: %{
          label: "Select input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Select input description"
        }
      }
    ]
  end
end
