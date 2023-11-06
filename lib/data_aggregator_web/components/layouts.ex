defmodule DataAggregatorWeb.Layouts do
  @moduledoc false

  use DataAggregatorWeb, :html

  embed_templates "layouts/*"

  def locale_select(assigns) do
    ~H"""
    <div id="locale-select-wrapper" phx-hook="LocaleSelect">
      <.menu id="locale-select">
        <.menu_button
          id="locale-select__button"
          class="dark:bg-gray-900 hover:text-gray-500 dark:hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-600 dark:focus-visible:ring-white focus-visible:ring-offset-2 dark:focus-visible:ring-offset-gray-900 relative flex items-center p-1 text-gray-400 bg-white rounded-full"
        >
          <span class="absolute -inset-1.5" />
          <.icon name="hero-globe-alt" class="w-6 h-6" />
          <span class="px-1"><%= current_locale() %></span>
        </.menu_button>
        <.menu_items id="locale-select__items" width="w-20">
          <div class="py-1" role="none">
            <.menu_item
              :for={locale <- locale_options()}
              as="div"
              id={"locale-select__item-#{locale.id}"}
              phx-click={
                JS.dispatch("set-locale", to: "#locale-select-wrapper", detail: locale[:value])
              }
            >
              <%= locale.label %>
              <span :if={current_locale() == locale.label} class="text-cyan-600 font-bold">
                &check;
              </span>
            </.menu_item>
          </div>
        </.menu_items>
      </.menu>
    </div>
    """
  end

  defp locale_options do
    DataAggregatorWeb.Locale.locales()
    |> Enum.map(fn x ->
      case x do
        "de-CH" -> option("DE", x)
        "fr-CH" -> option("FR", x)
        _ -> option("EN", x)
      end
    end)
  end

  defp option(label, value), do: %{id: value, label: label, value: value}

  defp current_locale do
    case DataAggregatorWeb.Locale.current().cldr_locale_name do
      :"de-CH" -> "DE"
      :"fr-CH" -> "FR"
      _ -> "EN"
    end
  end
end
