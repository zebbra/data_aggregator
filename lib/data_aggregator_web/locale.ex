defmodule DataAggregatorWeb.Locale do
  @moduledoc """
  Helper functions to work with locales.
  """

  require Logger

  import Plug.Conn, only: [assign: 3]

  def locales, do: ~w(en de-CH fr-CH)
  def current, do: DataAggregatorWeb.Cldr.get_locale()

  def put(locale_name) do
    {:ok, locale} = Cldr.validate_locale(locale_name, DataAggregatorWeb.Cldr)

    Logger.info("Locale set to #{inspect(locale)}")

    {:ok, _} = DataAggregatorWeb.Cldr.put_locale(locale)
    DataAggregatorWeb.Gettext.put_locale(locale.gettext_locale_name)

    {:ok, locale}
  end

  @spec assign_current_locale(Plug.Conn.t(), any) :: Plug.Conn.t()
  def assign_current_locale(conn, _opts \\ []) do
    assign(conn, :locale, current())
  end
end
