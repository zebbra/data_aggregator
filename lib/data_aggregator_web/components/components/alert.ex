defmodule DataAggregatorWeb.Components.Alert do
  @moduledoc """
  Alert components.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders an alert.

  Alerts should be placed within the `:portal` slot of the Layout component.

  ## Examples

  ```heex
  <.alert>
    This is an alert.
  </.alert>
  ```

  JS commands may be passed to the `:on_cancel` and/or `:on_confirm`
  to configure the closing/cancel/confirm event, for example:

  ```heex
  <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
    This is another modal.
  </.modal>
  ```

  You can use custom confirm alerts for method="delete" forms:

  ```heex
  <button
    phx-click={action}
    data-confirm={~t"Are you sure?"m}
    data-confirm_id="confirm_alert"
  >
    <.icon name={icon} class="size-5" />
    <span class="font-[sans-serif]"><%= label %></span>
  </button>

  <:portal>
    <.alert
      id="confirm_alert"
      size="sm"
      title={~t"Are you sure?"m}
      text={~t"You're about to delete this entry"m}
    >
    </.alert>
  </:portal>
  ```
  """
  attr :id, :string, required: true, doc: "The alert ID."
  attr :title, :string, default: nil, doc: "The alert title."
  attr :text, :string, default: nil, doc: "The alert text."
  attr :label, :string, default: nil, doc: "The alert button label."
  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the modal is cancelled."
  attr :on_confirm, JS, default: %JS{}, doc: "JS commands to run when the modal is closed."
  attr :form, :boolean, default: false, doc: "Whether the alert provides a form."
  attr :color, :string, values: ["blue", "green", "red", "orange", "primary"], default: "red"
  attr :disabled, :boolean, default: false, doc: "Whether the alert is disabled."

  attr :size, :string,
    values: ["xs", "sm", "md", "lg", "xl", "2xl", "3xl", "4xl", "5xl"],
    default: "md"

  slot :inner_block, required: false

  def alert(assigns) do
    ~H"""
    <dialog
      id={@id}
      role="alertdialog"
      class="modal"
      phx-hook="DialogHook"
      data-cancel={@on_cancel}
      data-confirm={@on_confirm}
      phx-update="ignore"
    >
      <div class={["modal-box max-h-[calc(100dvh-5em)]", size(@size)]}>
        <.focus_wrap id={"#{@id}_content"}>
          <h2 class="label-text text-base/6 font-semibold sm:text-sm/6">
            <%= @title || ~t"Are you sure?"m %>
          </h2>
          <p :if={@text} class="text-base/6 sm:text-sm/6"><%= @text %></p>
          <%= render_slot(@inner_block) %>
          <form :if={@form == false} method="dialog">
            <div class="modal-action">
              <button class="btn btn-ghost" value="cancel">
                <%= ~t"Cancel"m %>
              </button>
              <button
                type="submit"
                value="confirm"
                class={["btn", button_color(@color)]}
                disabled={@disabled}
              >
                <%= @label || ~t"OK"m %>
              </button>
            </div>
          </form>
        </.focus_wrap>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button><%= ~t"close"m %></button>
      </form>
    </dialog>
    """
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp size(size) do
    case size do
      "xs" -> "sm:max-w-xs"
      "sm" -> "sm:max-w-sm"
      "md" -> "sm:max-w-md"
      "lg" -> "sm:max-w-lg"
      "xl" -> "sm:max-w-xl"
      "2xl" -> "sm:max-w-2xl"
      "3xl" -> "sm:max-w-3xl"
      "4xl" -> "sm:max-w-4xl"
      "5xl" -> "sm:max-w-5xl"
      _ -> "sm:max-w-5xl"
    end
  end

  defp button_color("blue"), do: "btn-info"
  defp button_color("green"), do: "text-success"
  defp button_color("red"), do: "btn-error"
  defp button_color("orange"), do: "btn-warning"
  defp button_color(_), do: "btn-primary"
end
