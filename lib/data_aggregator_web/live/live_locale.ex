defmodule DataAggregatorWeb.LiveLocale do
  @moduledoc """
  LiveView hook to set the current locale for Cldr/Gettext from the sessions locale,
  which has been set by Cldr.
  """

  import Phoenix.Component, only: [assign: 2]

  require Logger

  def on_mount(:default, _params, session, socket) do
    {:ok, locale} = Cldr.Plug.put_locale_from_session(session)

    Logger.debug("LiveLocale set to #{inspect(locale)}")

    {:cont, assign(socket, locale: locale)}
  end
end
