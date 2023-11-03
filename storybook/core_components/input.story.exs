defmodule Storybook.CoreComponents.Input do
  use PhoenixStorybook.Story, :component

  alias Elixir.DataAggregatorWeb.CoreComponents

  def function, do: &CoreComponents.input/1
  def imports, do: [{CoreComponents, [simple_form: 1]}]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.lsb-variation-group field={f[:field]}/>
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
               range search tel text textarea time url week)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                label: String.capitalize("#{type} input")
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
