defmodule DataAggregatorWeb.Components.Transitions do
  @moduledoc false

  alias Phoenix.LiveView.JS

  ## JS Commands
  def show(js \\ %JS{}, selector) do
    js
    |> JS.show(
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-2 sm:translate-y-0 sm:translate-x-2",
         "opacity-100 translate-y-0 sm:translate-x-0"}
    )
    |> JS.remove_attribute("hidden", to: selector)
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 100,
      transition: {"transition-all transform ease-in duration-100", "opacity-100", "opacity-0"}
    )
  end
end
