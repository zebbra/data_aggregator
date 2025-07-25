defmodule DataAggregatorWeb.LiveLocale do
  @moduledoc """
  LiveView hook to set the current locale for Cldr/Gettext from the sessions locale,
  which has been set by Cldr.
  """

  import Phoenix.Component, only: [assign: 2]

  alias Cldr.LanguageTag

  require Logger

  def on_mount(:default, _params, session, socket) do
    {:ok, locale} = Cldr.Plug.put_locale_from_session(session)

    locale = if valid_locale?(locale), do: locale, else: DataAggregatorWeb.Cldr.default_locale()

    Logger.debug("LiveLocale set to #{inspect(locale)}")

    {:cont, assign(socket, locale: locale)}
  end

  defp valid_locale?(%LanguageTag{} = locale) do
    DataAggregatorWeb.Cldr.known_locale_name(locale.cldr_locale_name)
  end
end
