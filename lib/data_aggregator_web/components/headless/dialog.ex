defmodule DataAggregatorWeb.Headless.Dialog do
  @moduledoc """
  A fully-managed, renderless dialog component jam-packed with accessibility
  and keyboard features, perfect for building completely custom modal and
  dialog windows for your next application.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Headless.Description
  import DataAggregatorWeb.CoreComponents, only: [icon: 1, button: 1]

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :show, :boolean, default: false
  attr :role, :string, default: "dialog"
  attr :backdrop, :boolean, default: true
  attr :dialog_type, :string, default: "modal"
  attr :direction, :string, default: "right"
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}
  attr :rest, :global

  slot :inner_block, required: true

  def dialog(assigns) do
    ~H"""
    <.dynamic_tag
      phx-hook="Dialog"
      phx-mounted={
        @show &&
          show_dialog(@id, String.to_existing_atom(@dialog_type), String.to_existing_atom(@direction))
      }
      phx-remove={
        hide_dialog(@id, String.to_existing_atom(@dialog_type), String.to_existing_atom(@direction))
      }
      data-apply={JS.exec(@on_confirm, "phx-remove")}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-dialog_type={@dialog_type}
      id={@id}
      name={@as}
      role={@role}
      class={@rest[:class] || "hidden relative z-50"}
      {@rest}
    >
      <%= if @backdrop do %>
        <div
          id={@id <> "__backdrop"}
          class={[
            "hidden fixed inset-0",
            (@dialog_type == "modal" && "bg-black/50 dark:bg-white/5") ||
              "bg-gray-900/80"
          ]}
          aria-hidden="true"
        />
      <% end %>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: nil
  attr :dialog_type, :string, default: "modal"
  attr :direction, :string, default: "right"
  attr :rest, :global
  slot :inner_block, required: true

  slot :submit do
    attr :class, :string
  end

  slot :confirm do
    attr :class, :string
  end

  slot :cancel do
    attr :class, :string
  end

  def dialog_panel(assigns) do
    ~H"""
    <.focus_wrap
      id={"#{root_id(@id)}__focus-wrap"}
      class={String.to_existing_atom(@dialog_type) == :slideover && "flex flex-1 w-full"}
    >
      <.dynamic_tag
        phx-hook="DialogPanel"
        phx-click-away={JS.exec("data-cancel", to: "##{@id |> root_id}")}
        phx-window-keydown={JS.exec("data-cancel", to: "##{@id |> root_id}")}
        phx-key="escape"
        id={@id}
        name={@as}
        class={["hidden", @class]}
        {@rest}
      >
        <%= render_slot(@inner_block) %>
        <%= if Enum.empty?(@submit) == false || Enum.empty?(@confirm) == false || Enum.empty?(@cancel) == false do %>
          <div class="sm:mt-4 sm:flex sm:flex-row-reverse mt-5">
            <%= for submit <- @submit do %>
              <.button
                id={"#{@id |> root_id}__submit"}
                class={submit[:class] || "sm:ml-3 sm:w-auto inline-flex justify-center w-full"}
                phx-click={JS.exec("data-apply", to: "##{@id |> root_id}")}
                phx-disable-with
                {assigns_to_attributes(submit)}
              >
                <%= render_slot(submit) %>
              </.button>
            <% end %>
            <%= for confirm <- @confirm do %>
              <.button
                id={"#{@id |> root_id}__confirm"}
                variant="accent"
                class={confirm[:class] || "sm:ml-3 sm:w-auto inline-flex justify-center w-full"}
                phx-click={JS.exec("data-apply", to: "##{@id |> root_id}")}
                phx-disable-with
                {assigns_to_attributes(confirm)}
              >
                <%= render_slot(confirm) %>
              </.button>
            <% end %>
            <%= for cancel <- @cancel do %>
              <.button
                id={"#{@id |> root_id}__cancel"}
                variant="secondary"
                class={cancel[:class] || "mt-3 sm:mt-0 sm:w-auto inline-flex justify-center w-full"}
                phx-click={JS.exec("data-cancel", to: "##{@id |> root_id}")}
                {assigns_to_attributes(cancel)}
              >
                <%= render_slot(cancel) %>
              </.button>
            <% end %>
          </div>
        <% end %>
        <%= if String.to_existing_atom(@dialog_type) == :modal do %>
          <div class="sm:block absolute top-0 right-0 hidden pt-4 pr-4">
            <button
              phx-click={JS.exec("data-cancel", to: "##{@id |> root_id}")}
              type="button"
              class="hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 text-gray-400 bg-white dark:bg-gray-900 rounded-md"
              aria-label={gettext("close")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>
        <% else %>
          <%= if String.to_existing_atom(@direction) == :right do %>
            <div class="sm:-ml-10 sm:pr-4 absolute top-0 left-0 flex pt-4 pr-2 -ml-8">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id |> root_id}")}
                id={"#{@id |> root_id}__close"}
                type="button"
                class="hidden hover:text-white focus:outline-none focus:ring-2 focus:ring-white relative text-gray-300 rounded-md"
                aria-label={gettext("close")}
              >
                <span class="absolute -inset-2.5" />
                <span class="sr-only">Close panel</span>
                <.icon name="hero-x-mark" class="w-6 h-6 text-white" />
              </button>
            </div>
          <% else %>
            <div class="left-full absolute top-0 flex justify-center w-16 pt-5">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id |> root_id}")}
                id={"#{@id |> root_id}__close"}
                type="button"
                class="hidden -m-2.5 p-2.5"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark" class="w-6 h-6 text-white" />
              </button>
            </div>
          <% end %>
        <% end %>
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

  defp show_dialog(js \\ %JS{}, id, dialog_type, direction) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> show_backdrop(id, dialog_type)
    |> show_panel(id, dialog_type, direction)
    |> JS.set_attribute({"aria-modal", "true"}, to: "##{id}")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}__panel")
  end

  defp hide_dialog(js \\ %JS{}, id, dialog_type, direction) when is_binary(id) do
    js
    |> hide_backdrop(id, dialog_type)
    |> hide_panel(id, dialog_type, direction)
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_attribute("aria-modal", to: "##{id}")
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  defp show_backdrop(js, selector, dialog_type)

  defp show_backdrop(js, selector, :modal) do
    JS.show(js,
      to: "##{selector}__backdrop",
      display: "inline-block",
      time: 300,
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
  end

  defp show_backdrop(js, selector, :slideover) do
    js
    |> JS.show(
      to: "##{selector}__backdrop",
      display: "inline-block",
      time: 300,
      transition: {"ease-linear duration-300", "opacity-0", "opacity-100"}
    )
  end

  defp hide_backdrop(js, selector, dialog_type)

  defp hide_backdrop(js, selector, :modal) do
    JS.hide(js,
      to: "##{selector}__backdrop",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
  end

  defp hide_backdrop(js, selector, :slideover) do
    js
    |> JS.hide(
      to: "##{selector}__backdrop",
      time: 300,
      transition: {"ease-linear duration-300", "opacity-100", "opacity-0"}
    )
  end

  defp show_panel(js, selector, dialog_type, direction)

  defp show_panel(js, selector, :modal, _direction) do
    JS.show(js,
      to: "##{selector}__panel",
      display: "inline-block",
      time: 300,
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  defp show_panel(js, selector, :slideover, direction) do
    target = if direction == :right, do: "translate-x-full", else: "-translate-x-full"
    display = if direction == :right, do: "block", else: "flex"

    js
    |> JS.show(
      to: "##{selector}__panel",
      display: display,
      time: 300,
      transition: {"ease-in-out duration-300", target, "translate-x-0"}
    )
    |> show_close_button(selector)
  end

  defp hide_panel(js, selector, dialog_type, direction)

  defp hide_panel(js, selector, :modal, _direction) do
    JS.hide(js,
      to: "##{selector}__panel",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  defp hide_panel(js, selector, :slideover, direction) do
    target = if direction == :right, do: "translate-x-full", else: "-translate-x-full"

    js
    |> hide_close_button(selector)
    |> JS.hide(
      to: "##{selector}__panel",
      time: 300,
      transition: {"ease-in-out duration-300", "translate-x-0", target}
    )
  end

  defp show_close_button(js, selector) do
    JS.show(js,
      to: "##{selector}__close",
      time: 300,
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
  end

  defp hide_close_button(js, selector) do
    JS.hide(js,
      to: "##{selector}__close",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
  end

  defp root_id(id) do
    id
    |> String.split("__")
    |> List.first()
  end
end
