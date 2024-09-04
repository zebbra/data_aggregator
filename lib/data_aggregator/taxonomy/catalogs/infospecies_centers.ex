defmodule DataAggregator.Taxonomy.Catalogs.InfospeciesCenters do
  @moduledoc """
  The declaration of infospecies centers and helpers to deal with them
  """

  @centers [
    {:infofauna, ["julie.seemann-ricard@infofauna.ch"]},
    {:vogelwarte, ["data@vogelwarte.ch"]},
    {:infoflora, ["info@infoflora.ch"]},
    {:swissbryophytes, ["ann-michelle.hartwig@systbot.uzh.ch"]},
    {:swisslichens, ["swisslichens@wsl.ch"]},
    {:swissfungi, ["andrin.gross@wsl.ch", "bruno.aufdermaur@wsl.ch"]}
  ]

  @spec get_center_emails(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_center_emails(center) do
    case Enum.find(@centers, fn {name, _} -> name == center end) do
      nil -> {:error, "Center not found"}
      {_, emails} -> {:ok, emails}
    end
  end

  @spec get_centers() :: [{atom(), [String.t()]}]
  def get_centers, do: @centers

  @spec get_center_names() :: [atom()]
  def get_center_names, do: Enum.map(@centers, fn {name, _} -> name end)

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
