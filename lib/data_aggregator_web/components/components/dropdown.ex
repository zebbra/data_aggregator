defmodule DataAggregatorWeb.Components.Dropdown do
  @moduledoc """
  Dropdown components.
  """

  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a dropdown.

  ## Examples

      <.dropdown id="dropdown" class="dropdown-end" label="Language" icon="hero-language">
        <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px mt-16 w-44 gap-1 border p-2 shadow-2xl">
          <li :for={option <- options()}>
            <button
              type="button"
              class={option.selected && "active"}
              phx-click={
                JS.dispatch("set-locale", to: "#locale_selector_wrapper", detail: option.value)
              }
            >
              <span class="badge badge-sm badge-outline font-mono text-[.6rem] pt-px pr-1 pl-1.5 font-bold tracking-widest opacity-50">
                <%= option.short %>
              </span>
              <span class="font-[sans-serif]"><%= option.name %></span>
            </button>
          </li>
        </ul>
      </.dropdown>
  """
  attr(:id, :string, required: true, doc: "ID of the dropdown")
  attr(:class, :string, default: nil, doc: "Class to add to the dropdown")
  attr(:tooltip, :string, default: nil, doc: "Tooltip to add to the dropdown")
  attr(:icon, :string, default: nil, doc: "Icon to add to the dropdown")
  attr(:label, :string, default: nil, doc: "Label to add to the dropdown")

  slot(:inner_block, required: true, doc: "Actual content of the dropdown")
  slot(:summary, required: false, doc: "Custom summary of the dropdown")

  def dropdown(assigns) do
    ~H"""
    <details
      id={@id}
      class={[
        "dropdown hover:text-base-content",
        @class,
        @tooltip && "tooltip tooltip-bottom before:text-xs"
      ]}
      data-tip={@tooltip}
      phx-click-away={JS.remove_attribute("open", to: "##{@id}")}
      phx-window-keydown={JS.remove_attribute("open", to: "##{@id}")}
      phx-key="escape"
    >
      <%= if @summary != [] do %>
        <%= render_slot(@summary) %>
      <% else %>
        <summary class="btn btn-ghost text-base-content/75 hover:text-base-content">
          <.icon :if={@icon} name={@icon} />
          <span :if={@label}><%= @label %></span>
        </summary>
      <% end %>
      <%= render_slot(@inner_block) %>
    </details>
    """
  end

  attr(:id, :string, required: true, doc: "ID of the dropdown")
  slot(:inner_block, required: true, doc: "Actual content of the dropdown")

  def table_actions(assigns) do
    ~H"""
    <.dropdown id={@id} class="dropdown-left">
      <:summary>
        <summary class="btn btn-sm btn-ghost btn-square text-base-content/75 hover:text-base-content">
          <.icon name="hero-ellipsis-horizontal-micro" />
        </summary>
      </:summary>
      <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 z-10 w-28 gap-1 border p-2 shadow-lg">
        <%= render_slot(@inner_block) %>
      </ul>
    </.dropdown>
    """
  end
end
