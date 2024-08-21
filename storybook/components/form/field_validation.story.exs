defmodule Storybook.Components.Form.Field do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components

  def function, do: &Components.Field.field/1
  def imports, do: [{Components.Form, [simple_form: 1, fieldgroup: 1]}]

  def template do
    """
    <.simple_form :let={f} for={%{"field" => [""]}} as={:story} class="w-full">
      <.fieldgroup class="flex flex-col space-y-8">
        <.psb-variation-group field={%{f[:field] | errors: [{"is required", []}]}} required />
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
                ~w(checkbox date datetime-local email month number password
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
      %Variation{
        id: :select,
        attributes: %{
          label: "Select input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Select input description"
        }
      },
      %Variation{
        id: :multi_select,
        attributes: %{
          label: "Multiselect input",
          type: "select",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Multielect input description",
          multiple: true
        }
      },
      %Variation{
        id: :combobox,
        attributes: %{
          label: "Combobox input",
          type: "combobox",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Combobox input description"
        }
      }
    ]
  end
end
