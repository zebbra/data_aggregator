defmodule DataAggregatorWeb.Components.Icon do
  @moduledoc """
  Renders a [Heroicon](https://heroicons.com).
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="animate-spin w-3 h-3 ml-1" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" {@rest} />
    """
  end
end
