defmodule Storybook.Components.Dropdown do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Dropdown.dropdown/1

  def variations do
    [
      %Variation{
        id: :with_label,
        attributes: %{
          label: "EN"
        },
        slots: [
          content()
        ]
      },
      %Variation{
        id: :with_icon,
        attributes: %{
          icon: "hero-language"
        },
        slots: [
          content()
        ]
      },
      %Variation{
        id: :with_label_and_icon,
        attributes: %{
          label: "EN",
          icon: "hero-language"
        },
        slots: [
          content()
        ]
      },
      %Variation{
        id: :with_tooltip,
        attributes: %{
          label: "EN",
          icon: "hero-language",
          tooltip: "Language",
          class: "tooltip-left"
        },
        slots: [
          content()
        ]
      },
      %Variation{
        id: :with_position_end,
        attributes: %{
          label: "EN",
          icon: "hero-language",
          class: "dropdown-end"
        },
        slots: [
          content()
        ]
      },
      %Variation{
        id: :with_custom_summary,
        slots: [
          ~s|
<:summary>
  <summary class="btn text-base-content/75 hover:text-base-content">
    Custom
  </summary>
</:summary>|,
          content()
        ]
      }
    ]
  end

  def content do
    """
    <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-white/5 outline-black/5 top-px mt-16 w-44 gap-1 border p-2 shadow-2xl outline outline-1">
      <li>
        <button type="button" class="active">
          <span class="badge badge-sm badge-outline font-mono text-[.6rem] pt-px pr-1 pl-1.5 font-bold tracking-widest opacity-50">
            EN
          </span>
          <span class="font-[sans-serif]">English</span>
        </button>
      </li>
      <li>
        <button type="button">
          <span class="badge badge-sm badge-outline font-mono text-[.6rem] pt-px pr-1 pl-1.5 font-bold tracking-widest opacity-50">
            DE
          </span>
          <span class="font-[sans-serif]">Deutsch</span>
        </button>
      </li>
    </ul>
    """
  end
end
