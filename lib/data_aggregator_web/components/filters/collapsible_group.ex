defmodule DataAggregatorWeb.Filters.CollapsibleGroup do
  @moduledoc """
  Renders a collapsible to group a set of filters.

  Triggers the `collapsible_state:toggle` event on click.

  ## Example

  ```heex
  <.collapsible_group
    title={~t"Location"m}
    key="location"
    target={@target}
    open={open_collapsible?(@collapsible_state, "location")}
    border_bottom={false}
  >
    <.inputs_for :let={component} field={@component[:components]}>
      <.filter_form_component
        component={component}
        resource={@resource}
        collapsible_state={@collapsible_state}
        distinct_options={@distinct_options}
        target={@target}
      />
    </.inputs_for>
  </.collapsible_group>
  ```
  """
  use Phoenix.Component

  attr :open, :boolean,
    default: false,
    doc: "Whether the collapsible is open or closed"

  attr :title, :string,
    required: true,
    doc: "The title of the collapsible group"

  attr :key, :string,
    required: true,
    doc: "The key of the collapsible group"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  attr :border_bottom, :boolean,
    default: true,
    doc: "Whether to show a border at the bottom of the collapsible group"

  slot :inner_block, doc: "The content of the collapsible group"

  def collapsible_group(assigns) do
    ~H"""
    <details class="collapse collapse-arrow rounded-none px-6" open={@open}>
      <summary
        class="collapse-title text-base-content text-xl/6 max-w-4xl px-0 font-bold text-inherit max-sm:line-clamp-2 after:!end-1 sm:truncate"
        phx-click="collapsible_state:toggle"
        phx-value-key={@key}
        phx-target={@target}
      >
        {@title}
      </summary>
      <div class="collapse-content space-y-4 px-0 sm:space-y-6">
        {render_slot(@inner_block)}
      </div>
    </details>

    <div :if={@border_bottom} class="px-6">
      <div class="border-black-white/10 border-b pt-4" />
    </div>
    """
  end
end
