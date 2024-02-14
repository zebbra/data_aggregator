defmodule Storybook.Components.Form.Input do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Input.input/1
  def imports, do: [{Components.Form, [simple_form: 1, fieldgroup: 1]}]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.fieldgroup class="flex flex-col space-y-8">
        <.psb-variation-group field={f[:field]} required />
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
        id: :disabled_inputs,
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
                disabled: true
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
      %VariationGroup{
        id: :radio_disabled,
        variations:
          for option <- [:option_1, :option_2, :option_3] do
            %Variation{
              id: option,
              attributes: %{
                label: String.capitalize("#{option} input"),
                type: "radio",
                name: "radio_input",
                disabled: true
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
        id: :select_disabled,
        attributes: %{
          label: "Select input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          disabled: true
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
      },
      %Variation{
        id: :multi_select_disabled,
        attributes: %{
          label: "Multiselect input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          multiple: true,
          disabled: true
        }
      }
    ]
  end
end
