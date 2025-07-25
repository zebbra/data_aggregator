defmodule Storybook.Components.Tooltip do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components

  def function, do: &Components.FuiTooltip.fui_tooltip/1

  def template do
    """
    <button type="button" class="btn btn-sm btn-primary" aria-describedby=":variation_id">
      Show
    </button>
    <.psb-variation/>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :colors,
        variations:
          for color <- ~w(primary secondary accent info success warning error) do
            %Variation{
              id: String.to_atom(color),
              attributes: %{
                content: color,
                class: "fui-tooltip-#{color}",
                placement: "right",
                show_on_mount: true
              }
            }
          end
      },
      %VariationGroup{
        id: :placement,
        variations:
          for placement <-
                ~w(top right bottom left top-start right-start bottom-start left-start top-end right-end bottom-end left-end) do
            %Variation{
              id: String.to_atom(placement),
              attributes: %{
                content: placement,
                placement: placement,
                show_on_mount: true
              }
            }
          end
      },
      %Variation{
        id: :offset,
        attributes: %{
          content: "offset",
          offset_opts: 32,
          show_on_mount: true
        }
      },
      %Variation{
        id: :flip,
        attributes: %{
          content: "offset",
          placement: "bottom",
          flip_opts: true,
          show_on_mount: true
        }
      },
      %Variation{
        id: :shift,
        attributes: %{
          content: "Would shift if needed",
          placement: "bottom",
          shift_opts: true,
          show_on_mount: true
        }
      },
      %Variation{
        id: :no_arrow,
        attributes: %{
          content: "No arrow",
          arrow: false,
          offset_opts: 2,
          show_on_mount: true
        }
      },
      %Variation{
        id: :custom_visibility,
        attributes: %{
          content: "custom visibility",
          visibility_class: "hidden lg:hidden",
          show_class: "lg:block",
          hide_class: "lg:hidden",
          show_on_mount: true
        }
      }
    ]
  end
end
