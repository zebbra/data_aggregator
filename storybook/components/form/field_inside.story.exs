defmodule Storybook.Components.Form.FieldInside do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Field.field/1

  def imports,
    do: [{Components.Form, [simple_form: 1, fieldgroup: 1]}, {Components.Icon, [icon: 1]}]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.fieldgroup>
        <.psb-variation-group field={f[:field]} required inside />
      </.fieldgroup>
    </.simple_form>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :inside_inputs,
        variations:
          for type <-
                ~w(email number password tel text url)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                autocomplete: to_string(type),
                placeholder: String.capitalize("#{type} input")
              },
              slots: [
                icon(to_string(type))
              ]
            }
          end
      },
      %VariationGroup{
        id: :inside_inputs_after,
        variations:
          for type <-
                ~w(email number password tel text url)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                autocomplete: to_string(type),
                placeholder: String.capitalize("#{type} input")
              },
              slots: [
                icon_after(to_string(type))
              ]
            }
          end
      },
      %VariationGroup{
        id: :inside_label,
        variations:
          for type <-
                ~w(email number password tel text url)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                autocomplete: to_string(type),
                label: String.capitalize("#{type} input:")
              }
            }
          end
      }
    ]
  end

  defp icon_after(type) do
    icon =
      case type do
        "email" -> "hero-envelope-mini"
        "number" -> "hero-calculator-mini"
        "password" -> "hero-key-mini"
        "tel" -> "hero-phone-mini"
        "text" -> "hero-user-mini"
        "url" -> "hero-link-mini"
      end

    """
    <:after_input>
      <.icon name={"#{icon}"} class="opacity-70" />
    </:after_input>
    """
  end

  defp icon(type) do
    icon =
      case type do
        "email" -> "hero-envelope-mini"
        "number" -> "hero-calculator-mini"
        "password" -> "hero-key-mini"
        "tel" -> "hero-phone-mini"
        "text" -> "hero-user-mini"
        "url" -> "hero-link-mini"
      end

    """
    <:before_input>
      <.icon name={"#{icon}"} class="opacity-70" />
    </:before_input>
    """
  end
end
