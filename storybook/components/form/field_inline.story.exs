defmodule Storybook.Components.Form.FieldInline do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components

  def function, do: &Components.Field.field/1
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
        id: :inline_inputs_start_icon,
        variations:
          for type <-
                ~w(checkbox color date datetime-local email hidden month number password
               range search tel text textarea time url week toggle file)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                label: String.capitalize("#{type} input"),
                icon_start: icon_lookup(to_string(type)),
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
      },
      %Variation{
        id: :combobox,
        attributes: %{
          label: "Combobox input",
          type: "combobox",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Combobox input description"
        }
      },
      %Variation{
        id: :combobox_multiple,
        attributes: %{
          label: "Combobox input",
          type: "combobox",
          options: ["Option 1", "Option 2", "Option 3"],
          description: "Combobox input description",
          multiple: true
        }
      }
    ]
  end

  defp icon_lookup(type) do
    cond do
      type == "color" -> "hero-swatch-mini"
      type == "date" -> "hero-calendar-days-mini"
      type == "datetime-local" -> "hero-calendar-days-mini"
      type == "email" -> "hero-envelope-mini"
      type == "month" -> "hero-calendar-days-mini"
      type == "number" -> "hero-calculator-mini"
      type == "password" -> "hero-key-mini"
      type == "search" -> "hero-magnifying-glass-mini"
      type == "tel" -> "hero-phone-mini"
      type == "text" -> "hero-user-mini"
      type == "time" -> "hero-clock-mini"
      type == "url" -> "hero-link-mini"
      type == "week" -> "hero-calendar-days-mini"
      true -> "hero-user-mini"
    end
  end
end
