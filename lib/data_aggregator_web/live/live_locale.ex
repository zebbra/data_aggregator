defmodule DataAggregatorWeb.LiveLocale do
  @moduledoc """
  LiveView hook to set the current locale for Cldr/Gettext from the sessions locale,
  which has been set by Cldr.
  """

  import Phoenix.Component, only: [assign: 2]

  def on_mount(:default, _params, session, socket) do
    {:ok, locale} = Cldr.Plug.put_locale_from_session(session)
    {:cont, socket |> assign(locale: locale)}
  end
end
