defmodule DataAggregatorWeb.Components.Progress do
  @moduledoc """
  Progress bars
  """

  use Phoenix.Component

  attr :size, :string,
    default: "sm",
    values: ["xs", "sm", "md", "lg", "xl"]

  attr :color, :string,
    default: "primary",
    values: ["primary"]

  attr :label, :string, default: nil, doc: "labels your progress bar [xl only]"
  attr :value, :integer, default: nil, doc: "adds a value to your progress bar"
  attr :max, :integer, default: 100, doc: "sets a max value for your progress bar"
  attr :class, :string, default: "", doc: "CSS class"
  attr :rest, :global

  def progress(assigns) do
    assigns =
      assigns
      |> assign(:outer_classes, outer_classes(assigns))
      |> assign(:inner_classes, inner_classes(assigns))

    ~H"""
    <div class={[@outer_classes, "w-full rounded-full overflow-hidden", @class]} {@rest}>
      <div class={[@inner_classes]} style={"width: #{round(@value/@max*100)}%"}>
        <%= if @size == "xl" do %>
          <span class="whitespace-nowrap font-xs px-4 font-normal text-center">
            <%= @label %>
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  defp outer_classes(opts) do
    size_classes(opts) ++ outer_color_classes(opts)
  end

  defp inner_classes(opts) do
    size_classes(opts) ++ inner_color_classes(opts)
  end

  defp size_classes(%{size: "xs"}), do: ["h-1"]
  defp size_classes(%{size: "sm"}), do: ["h-2"]
  defp size_classes(%{size: "md"}), do: ["h-3"]
  defp size_classes(%{size: "lg"}), do: ["h-4"]

  defp size_classes(%{size: "xl", label: label}) when is_binary(label),
    do: ["h-5 flex flex-col justify-center"]

  defp size_classes(%{size: "xl"}), do: ["h-5"]

  defp outer_color_classes(%{color: "primary"}), do: ["bg-gray-200 dark:bg-gray-700"]

  defp inner_color_classes(%{color: "primary"}), do: ["bg-indigo-500 dark:bg-indigo-500"]
end
