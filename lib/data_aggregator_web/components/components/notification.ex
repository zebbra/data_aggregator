defmodule DataAggregatorWeb.Components.Notification do
  @moduledoc """
  This module contains components for the notification.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a collapsible notification with a message and collapsible content.

  ## Examples

  ```heex
  <.notification title="An error has occurred" color="red">
    <:action>
      Show more
    </:action>
    Details about the error
  </.notification>
  ```
  """
  attr :title, :string, required: true, doc: "the title of the notification"
  attr :class, :string, default: nil, doc: "the class of the notification"

  attr :color, :string,
    default: "blue",
    values: ~w(gray blue green red orange),
    doc: "the color of the notification"

  slot :action, doc: "the optional action region to show on the right side of the title" do
    attr :class, :string, doc: "the action class"
  end

  slot :inner_block, required: true, doc: "the inner block (detail message) of the notification"

  def collapsible_notification(assigns) do
    ~H"""
    <div class={["collapse border", notification_color(@color)]}>
      <input type="checkbox" />
      <div class={[
        "collapse-title pe-4 flex items-center gap-x-2 text-sm max-sm:flex-col max-sm:items-start max-sm:gap-y-2",
        @class,
        notification_text_color(@color)
      ]}>
        <div class="flex min-w-0 flex-1 items-center gap-x-2">
          <.icon name={notification_icon(@color)} />
          <span>{@title}</span>
        </div>
        <div :for={action <- @action} class={action[:class]}>
          {render_slot(action)}
        </div>
      </div>
      <div class="collapse-content">
        <div class={["text-sm/6", notification_text_color(@color)]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp notification_color("blue"), do: "text-info-content border-info/20 bg-info/10"
  defp notification_color("green"), do: "text-success-content border-success/20 bg-success/10"
  defp notification_color("red"), do: "text-error-content border-error/20 bg-error/10"
  defp notification_color("orange"), do: "text-warning-content border-warning/20 bg-warning/10"
  defp notification_color(_), do: "text-base-content/60 border-base-content/30 bg-base-300"

  defp notification_text_color("blue"), do: "text-info"
  defp notification_text_color("green"), do: "text-success"
  defp notification_text_color("red"), do: "text-error"
  defp notification_text_color("orange"), do: "text-warning"
  defp notification_text_color(_), do: "text-base-content/60"

  defp notification_icon("blue"), do: "hero-information-circle-solid"
  defp notification_icon("green"), do: "hero-check-circle-solid"
  defp notification_icon("red"), do: "hero-exclamation-triangle"
  defp notification_icon("orange"), do: "hero-exclamation-circle"
  defp notification_icon(_), do: "hero-information-circle-solid"
end
