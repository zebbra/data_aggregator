defmodule DataAggregatorWeb.LocaleSelect do
  @moduledoc """
  A component to select the current locale.
  """
  use DataAggregatorWeb, :live_component

  @impl true
  def render(assigns) do
    data =
      %{
        value: selected(DataAggregatorWeb.Locale.current()),
        locales: options(DataAggregatorWeb.Locale.locales())
      }

    assigns =
      assigns
      |> assign(data: data)

    ~H"""
    <div
      x-data={Jason.encode!(@data)}
      x-init="() => { $watch('value', ({ value }) => $dispatch('set-locale', value) ) }"
    >
      <div
        x-listbox
        x-model="value"
        x-bind:by="(a, b) => a && b && a['value'] == b['value']"
        class="relative"
      >
        <label x-listbox:label class="sr-only">Locale select</label>
        <button
          x-listbox:button
          type="button"
          class="relative rounded-full bg-white dark:bg-gray-900 p-1 text-gray-400 hover:text-gray-500 dark:hover:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 dark:focus:ring-white focus:ring-offset-2 dark:focus:ring-offset-gray-900"
        >
          <span class="absolute -inset-1.5" />
          <.icon name="hero-globe-alt" class="w-6 h-6" />
          <span x-text="value.label" class="pr-1" />
        </button>
        <%!-- x-cloak on ul does not work, this is a workaround to prevent dropdown from flicker --%>
        <template x-if="true">
          <ul
            x-listbox:options
            x-transition.origin.top.right
            class="absolute right-0 w-20 mt-2.5 z-10 origin-top-right bg-white py-2 rounded-md shadow-lg ring-1 ring-gray-900/5 ring-opacity-5 focus:outline-none"
          >
            <template x-for="locale in locales" x-bind:key="locale.id">
              <li
                x-listbox:option
                x-bind:value="locale"
                x-bind:class="{
                'bg-cyan-500/10 text-gray-900': $listboxOption.isActive,
                'text-gray-600': ! $listboxOption.isActive
              }"
                class="flex items-center cursor-default justify-between gap-2 w-full px-4 py-2 text-sm transition-colors"
              >
                <span x-text="locale.label" />
                <span x-show="$listboxOption.isSelected" class="text-cyan-600 font-bold">
                  &check;
                </span>
              </li>
            </template>
          </ul>
        </template>
      </div>
    </div>
    """
  end

  defp options(options) do
    options
    |> Enum.map(fn x ->
      case x do
        "de-CH" -> option("DE", x)
        "fr-CH" -> option("FR", x)
        _ -> option("EN", x)
      end
    end)
  end

  defp selected(locale) do
    case locale.gettext_locale_name do
      "de" -> option("DE", locale.cldr_locale_name)
      "fr" -> option("FR", locale.cldr_locale_name)
      _ -> option("EN", locale.cldr_locale_name)
    end
  end

  defp option(label, value), do: %{id: value, label: label, value: value}
end
