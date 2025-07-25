defmodule DataAggregator.Taxonomy.Catalogs.InfospeciesCenters do
  @moduledoc """
  The declaration of infospecies centers and helpers to deal with them
  """

  @spec get_center_emails(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_center_emails(center) do
    case Enum.find(get_centers(), fn {name, _, _} -> name == center end) do
      nil -> {:error, "Center not found"}
      {_, emails, _} -> {:ok, emails}
    end
  end

  @spec get_website(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_website(center) do
    case Enum.find(get_centers(), fn {name, _, _} -> name == center end) do
      nil -> {:error, "Center not found"}
      {_, _, website} -> {:ok, website}
    end
  end

  @spec get_centers() :: [{atom(), [String.t()], String.t()}]
  def get_centers,
    do: [
      {:infofauna, ["julie.seemann-ricard@infofauna.ch"], "https://www.infofauna.ch"},
      {:vogelwarte, ["data@vogelwarte.ch"], "https://www.vogelwarte.ch"},
      {:infoflora, ["info@infoflora.ch"], "https://www.infoflora.ch"},
      {:swissbryophytes, ["ann-michelle.hartwig@systbot.uzh.ch"], "https://www.swissbryophytes.ch"},
      {:swisslichens, ["swisslichens@wsl.ch"], "https://www.swisslichens.ch"},
      {:swissfungi, ["andrin.gross@wsl.ch", "bruno.aufdermaur@wsl.ch"], "https://www.swissfungi.ch"}
    ]

  @spec get_center_names() :: [atom()]
  def get_center_names, do: Enum.map(get_centers(), fn {name, _, _} -> name end)

  def translate_center(center) do
    case center do
      :infofauna -> "info fauna"
      :vogelwarte -> "Schweizerische Vogelwarte"
      :infoflora -> "InfoFlora"
      :swissbryophytes -> "SwissBryophytes"
      :swisslichens -> "SwissLichens"
      :swissfungi -> "SwissFungi"
    end
  end
end
