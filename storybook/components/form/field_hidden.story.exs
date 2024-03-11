defmodule Storybook.Components.Form.FieldHidden do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components

  def function, do: &Components.Field.field/1
  def imports, do: [{Components.Form, [simple_form: 1, fieldgroup: 1]}]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.fieldgroup class="space-y-2" inline>
        <.psb-variation-group field={f[:field]} required hidden />
      </.fieldgroup>
    </.simple_form>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :hidden_inputs,
        variations:
          for type <-
                ~w(checkbox color date datetime-local email hidden month number password
               range search tel text textarea time url week toggle file)a do
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
        id: :radio_hidden,
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
        id: :select_hidden,
        attributes: %{
          label: "Select input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Select input description"
        }
      },
      %Variation{
        id: :multi_select_hidden,
        attributes: %{
          label: "Multiselect input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Multielect input description",
          multiple: true
        }
      },
      %Variation{
        id: :combobox_hidden,
        attributes: %{
          label: "Combobox input",
          type: "combobox",
          options: ["Option 1", "Option 2", "Option 3"]
        }
      }
    ]
  end
end
