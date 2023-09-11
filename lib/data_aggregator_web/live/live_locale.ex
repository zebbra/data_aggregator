defmodule DataAggregatorWeb.LiveLocale do
  @moduledoc """
  LiveView hook to set the current locale for Cldr/Gettext from the sessions locale,
  which has been set by Cldr.
  """

  import Phoenix.LiveView, only: [attach_hook: 4]
  import Phoenix.Component, only: [assign: 2]

  def on_mount(:default, _params, session, socket) do
    {:ok, locale} = Cldr.Plug.put_locale_from_session(session)

    {:cont,
     socket
     |> assign(locale: locale)
     |> attach_hook(:locale, :handle_event, &handle_event/3)}
  end

  defp handle_event("set-locale", %{"locale" => locale}, socket) do
    {:ok, locale} = DataAggregatorWeb.Locale.put(locale)
    {:halt, socket |> assign(locale: locale)}
  end

  defp handle_event(_event, _params, socket), do: {:cont, socket}
end
