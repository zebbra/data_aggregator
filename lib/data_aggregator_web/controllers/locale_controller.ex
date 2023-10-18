defmodule DataAggregatorWeb.LocaleController do
  @moduledoc """
  This controller allows changing the session from live components.
  """

  use DataAggregatorWeb, :controller

  @doc """
  This method is just a dummy method. The locale is already set using plugs.
  """
  def set(conn, _params) do
    %Cldr.LanguageTag{canonical_locale_name: locale} = DataAggregatorWeb.Locale.current()
    conn |> text(locale)
  end
end
