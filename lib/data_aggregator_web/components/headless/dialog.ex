defmodule DataAggregatorWeb.Headless.Dialog do
  @moduledoc """
  A fully-managed, renderless dialog component jam-packed with accessibility
  and keyboard features, perfect for building completely custom modal and
  dialog windows for your next application.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Headless.Description
  import DataAggregatorWeb.Headless.Helpers

  @doc ~S"""
  Renders a dialog component. Per default you set show to true and render the dialog
  conditionaly with the :if directive. However, if a dialog must be visible / hidden
  base on client window width, this approach does not work. In this case you can use
  the responsive attribute to set the breakpoint at which the dialog should be visible
  or hidden. Make sure to set the show attribute to false in this case. If you want to
  a dynamic show attribute (instead of the :if directive) to render the dialog together
  with the responsive attribute, you need to mark the dialog as static.

  Further we do currently not support multiple dialogs on the same page. The on_<action>
  callbacks get executed on all dialogs on the page which is not correct. Maybe we can
  fix this later.
  """

  attr :id, :string, required: true

  attr :parent_id, :string,
    default: nil,
    doc: "the id of the parent component if it's a nested dialog"

  attr :as, :string, default: "div"
  attr :show, :boolean, default: false
  attr :static, :boolean, default: false
  attr :responsive, :string, default: nil
  attr :class, :string, default: nil
  attr :role, :string, default: "dialog"
  attr :backdrop, :boolean, default: true
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :display, :string, default: "inline-block"
  attr :show_panel_transition, :map, default: nil
  attr :hide_panel_transition, :map, default: nil
  attr :show_backdrop_transition, :map, default: nil
  attr :hide_backdrop_transition, :map, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def dialog(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="Dialog"
      phx-mounted={
        @show &&
          show_dialog(@id, @show_panel_transition, @show_backdrop_transition, @display)
      }
      phx-remove={hide_dialog(@id, @hide_panel_transition, @hide_backdrop_transition)}
      data-apply={JS.exec(@on_confirm, "phx-remove")}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-show={
        !@show && show_dialog(@id, @show_panel_transition, @show_backdrop_transition, @display)
      }
      data-hide={hide_dialog(@id, @hide_panel_transition, @hide_backdrop_transition)}
      data-responsive={@responsive}
      data-static={@static}
      data-parentid={@parent_id}
      id={@id}
      name={@as}
      role={@role}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: nil
  attr :slideover, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def dialog_panel(assigns) do
    ~H"""
    <.focus_wrap id={"#{root_id(@id)}__focus-wrap"} class={@slideover && "flex flex-1 w-full"}>
      <.dynamic_tag
        phx-hook="DialogPanel"
        phx-click-away={JS.exec("data-cancel", to: "##{@id |> root_id}")}
        id={@id}
        name={@as}
        class={["hidden", @class]}
        {@rest}
      >
        <%= render_slot(@inner_block) %>
      </.dynamic_tag>
    </.focus_wrap>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "h2"
  attr :rest, :global
  slot :inner_block, required: true

  def dialog_title(assigns) do
    ~H"""
    <.dynamic_tag phx-hook="DialogTitle" id={@id} name={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "p"
  attr :rest, :global
  slot :inner_block, required: true

  def dialog_description(assigns) do
    ~H"""
    <.description phx-hook="Description" id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.description>
    """
  end

  defp show_dialog(js \\ %JS{}, id, panel_transition, backdrop_transition, display)
       when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> show_backdrop(id, backdrop_transition)
    |> show_panel(id, panel_transition, display)
    |> JS.set_attribute({"aria-modal", "true"}, to: "##{id}")
    |> JS.focus_first(to: "##{id}__panel")
  end

  defp hide_dialog(js \\ %JS{}, id, panel_transition, backdrop_transition) when is_binary(id) do
    js
    |> hide_backdrop(id, backdrop_transition)
    |> hide_panel(id, panel_transition)
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_attribute("aria-modal", to: "##{id}")
  end

  defp show_backdrop(js, selector, transition) do
    time = extract_duration(transition)

    js
    |> JS.show(
      to: "##{selector}__backdrop",
      display: "inline-block",
      time: time,
      transition: transition
    )
  end

  defp hide_backdrop(js, selector, transition) do
    time = extract_duration(transition)

    js
    |> JS.hide(
      to: "##{selector}__backdrop",
      time: time,
      transition: transition
    )
  end

  defp show_panel(js, selector, transition, display) do
    time = extract_duration(transition)

    js
    |> JS.show(
      to: "##{selector}__panel",
      display: display,
      time: time,
      transition: transition
    )
    |> show_close_button(selector)
  end

  defp hide_panel(js, selector, transition) do
    time = extract_duration(transition)

    js
    |> hide_close_button(selector)
    |> JS.hide(
      to: "##{selector}__panel",
      time: time,
      transition: transition
    )
  end

  defp show_close_button(js, selector) do
    js
    |> JS.show(
      to: "##{selector}__close",
      time: 300,
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
  end

  defp hide_close_button(js, selector) do
    js
    |> JS.hide(
      to: "##{selector}__close",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
  end
end
