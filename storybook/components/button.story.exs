defmodule Storybook.Components.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Button

  def function, do: &Button.button/1

  def variations do
    [
      %VariationGroup{
        id: :submit,
        variations:
          for type <- [
                %{
                  label: "Submit",
                  type: "submit",
                  class: false,
                  disabled: false,
                  responsive: false,
                  icon: nil
                },
                %{
                  label: "Loading",
                  type: "submit",
                  class: "phx-submit-loading",
                  disabled: false,
                  responsive: false,
                  icon: nil
                },
                %{
                  label: "Disabled",
                  type: "submit",
                  class: false,
                  disabled: true,
                  responsive: false,
                  icon: nil
                },
                %{
                  label: "Loading and disabled",
                  type: "submit",
                  class: "phx-submit-loading",
                  disabled: true,
                  responsive: false,
                  icon: nil
                },
                %{
                  label: "Responsive with icon",
                  type: "submit",
                  class: false,
                  disabled: false,
                  responsive: true,
                  icon: "hero-plus-circle-mini"
                },
                %{
                  label: "Responsive with icon and loading",
                  type: "submit",
                  class: "phx-submit-loading",
                  disabled: false,
                  responsive: true,
                  icon: "hero-plus-circle-mini"
                }
              ] do
            %Variation{
              id: String.to_atom(type.label),
              attributes: %{
                type: type.type,
                label: type.label,
                class: type.class,
                disabled: type.disabled,
                responsive: type.responsive,
                icon: type.icon
              }
            }
          end
      },
      %VariationGroup{
        id: :types,
        variations:
          for type <- [
                %{label: "Button", link_type: "button", method: nil},
                %{label: "Link", link_type: "a", method: nil},
                %{label: "Link with method", link_type: "a", method: :delete},
                %{label: "Patch", link_type: "live_patch", method: nil},
                %{label: "Navigate", link_type: "live_redirect", method: nil}
              ] do
            %Variation{
              id: String.to_atom(type.label),
              attributes: %{
                link_type: type.link_type,
                to: "/",
                label: type.label,
                method: type.method
              }
            }
          end
      },
      %VariationGroup{
        id: :colors,
        variations:
          for color <- [
                %{label: "Primary", color: "primary"},
                %{label: "Secondary", color: "secondary"},
                %{label: "Accent", color: "accent"},
                %{label: "Simple", color: "simple"}
              ] do
            %Variation{
              id: String.to_atom(color.label),
              attributes: %{
                color: color.color,
                label: color.label
              }
            }
          end
      },
      %VariationGroup{
        id: :disabled,
        variations:
          for color <- [
                %{label: "Primary", color: "primary", link_type: "button"},
                %{label: "Secondary", color: "secondary", link_type: "a"},
                %{label: "Accent", color: "accent", link_type: "live_patch"},
                %{label: "Simple", color: "simple", link_type: "live_redirect"}
              ] do
            %Variation{
              id: String.to_atom(color.label),
              attributes: %{
                color: color.color,
                label: color.label,
                disabled: true,
                link_type: color.link_type,
                to: "/"
              }
            }
          end
      },
      %VariationGroup{
        id: :sizes,
        variations:
          for size <- [
                %{label: "Extra small", size: "xs"},
                %{label: "Small", size: "sm"},
                %{label: "Medium", size: "md"},
                %{label: "Large", size: "lg"},
                %{label: "Extra large", size: "xl"}
              ] do
            %Variation{
              id: String.to_atom(size.label),
              attributes: %{
                label: size.label,
                size: size.size
              }
            }
          end
      },
      %VariationGroup{
        id: :loading,
        variations:
          for size <- [
                %{label: nil, size: "md", link_type: "button"},
                %{label: "Extra small", size: "xs", link_type: "a"},
                %{label: "Small", size: "sm", link_type: "live_patch"},
                %{label: "Medium", size: "md", link_type: "live_redirect"},
                %{label: "Large", size: "lg", link_type: "button"},
                %{label: "Extra large", size: "xl", link_type: "button"}
              ] do
            %Variation{
              id: String.to_atom(to_string(size.label)),
              attributes: %{
                label: size.label,
                size: size.size,
                loading: true,
                link_type: size.link_type,
                to: "/"
              }
            }
          end
      },
      %VariationGroup{
        id: :icons,
        variations:
          for icon <- [
                %{label: nil, icon: "hero-plus-circle-mini", size: "md", link_type: "button"},
                %{
                  label: "Icon on XS",
                  icon: "hero-check-circle-mini",
                  size: "xs",
                  link_type: "button"
                },
                %{
                  label: "Icon on SM",
                  icon: "hero-check-circle-mini",
                  size: "sm",
                  link_type: "a"
                },
                %{
                  label: "Icon on MD",
                  icon: "hero-check-circle-mini",
                  size: "md",
                  link_type: "live_patch"
                },
                %{
                  label: "Icon on LG",
                  icon: "hero-check-circle-mini",
                  size: "lg",
                  link_type: "live_redirect"
                },
                %{
                  label: "Icon on XL",
                  icon: "hero-check-circle-mini",
                  size: "xl",
                  link_type: "button"
                }
              ] do
            %Variation{
              id: String.to_atom(to_string(icon.label)),
              attributes: %{
                label: icon.label,
                icon: icon.icon,
                size: icon.size,
                link_type: icon.link_type,
                to: "/"
              }
            }
          end
      },
      %VariationGroup{
        id: :responsive,
        variations:
          for icon <- [
                %{
                  label: "Icon on XS",
                  icon: "hero-check-circle-mini",
                  size: "xs",
                  link_type: "button"
                },
                %{
                  label: "Icon on SM",
                  icon: "hero-check-circle-mini",
                  size: "sm",
                  link_type: "a"
                },
                %{
                  label: "Icon on MD",
                  icon: "hero-check-circle-mini",
                  size: "md",
                  link_type: "live_patch"
                },
                %{
                  label: "Icon on LG",
                  icon: "hero-check-circle-mini",
                  size: "lg",
                  link_type: "live_redirect"
                },
                %{
                  label: "Icon on XL",
                  icon: "hero-check-circle-mini",
                  size: "xl",
                  link_type: "button"
                }
              ] do
            %Variation{
              id: String.to_atom(to_string(icon.label)),
              attributes: %{
                label: icon.label,
                icon: icon.icon,
                size: icon.size,
                link_type: icon.link_type,
                to: "/",
                responsive: true
              }
            }
          end
      }
    ]
  end
end
