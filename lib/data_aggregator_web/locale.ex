defmodule DataAggregatorWeb.Locale do
  @moduledoc """
  Helper functions to work with locales.
  """

  require Logger

  import Plug.Conn, only: [assign: 3]

  def locales, do: ~w(en de-CH fr-CH)
  def current, do: DataAggregatorWeb.Cldr.get_locale()

  @spec assign_current_locale(Plug.Conn.t(), any) :: Plug.Conn.t()
  def assign_current_locale(conn, _opts \\ []) do
    Logger.debug("Assign locale #{inspect(current())}")
    assign(conn, :locale, current())
  end
end
