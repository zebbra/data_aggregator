defmodule DataAggregator.Taxonomy.Catalogs.InfospeciesCenters do
  @moduledoc """
  The declaration of infospecies centers and helpers to deal with them
  """

  @doc """
  returns the emails of a given infospecies center as enum
  """
  @spec get_center_emails(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_center_emails(center) do
    case Enum.find(get_centers(), fn {name, _, _} -> name == center end) do
      nil -> {:error, "Center not found"}
      {_, emails, _} -> {:ok, emails}
    end
  end

  @doc """
  returns the website of a given infospecies center as string
  """
  @spec get_website(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_website(center) do
    case Enum.find(get_centers(), fn {name, _, _} -> name == center end) do
      nil -> {:error, "Center not found"}
      {_, _, website} -> {:ok, website}
    end
  end

  @doc """
  returns the names of all infospecies centers as atoms in an enum
  """
  @spec get_center_names() :: [atom()]
  def get_center_names, do: Enum.map(get_centers(), fn {name, _, _} -> name end)

  @doc """
  returns the plain infospecies config
  """
  @spec get_centers() :: [{atom(), [String.t()], String.t()}]
  def get_centers,
    do: [
      {:infofauna, get_center_mails!("CENTER_EMAIL_INFOFAUNA"), "https://www.infofauna.ch"},
      {:vogelwarte, get_center_mails!("CENTER_EMAIL_VOGELWARTE"), "https://www.vogelwarte.ch"},
      {:infoflora, get_center_mails!("CENTER_EMAIL_INFOFLORA"), "https://www.infoflora.ch"},
      {:swissbryophytes, get_center_mails!("CENTER_EMAIL_SWISSBRYOPHYTES"), "https://www.swissbryophytes.ch"},
      {:swisslichens, get_center_mails!("CENTER_EMAIL_SWISSLICHENS"), "https://www.swisslichens.ch"},
      {:swissfungi, get_center_mails!("CENTER_EMAIL_SWISSFUNGI"), "https://www.swissfungi.ch"}
    ]

  def translate_center(center) do
    case center do
      :infofauna -> "Info Fauna"
      :vogelwarte -> "Schweizerische Vogelwarte"
      :infoflora -> "InfoFlora"
      :swissbryophytes -> "SwissBryophytes"
      :swisslichens -> "SwissLichens"
      :swissfungi -> "SwissFungi"
    end
  end

  defp get_center_mails!(env_var) do
    case System.get_env(env_var) do
      nil -> raise "Could not find Infospecies config. Environment variable #{env_var} not set."
      mail_addrs -> String.split(mail_addrs)
    end
  end
end
