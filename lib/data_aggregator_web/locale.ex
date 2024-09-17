defmodule DataAggregatorWeb.Locale do
  @moduledoc """
  Helper functions to work with locales.
  """

  import Plug.Conn, only: [assign: 3]

  require Logger

  def locales, do: ~w(en)
  def current, do: DataAggregatorWeb.Cldr.get_locale()

  @spec assign_current_locale(Plug.Conn.t(), any) :: Plug.Conn.t()
  def assign_current_locale(conn, _opts \\ []) do
    Logger.debug("Assign locale #{inspect(current())}")
    assign(conn, :locale, current())
  end
end
