defmodule DataAggregator.Gbif.RestApi do
  @moduledoc """
  Module to interact with the GBIF Rest API
  """

  def register_dataset(collection_name) do
    Req.post(
      url: System.get_env("GBIF_DATASET_URL"),
      auth: gbif_auth(),
      json: registration_params(collection_name)
    )
  end

  defp registration_params(collection_name) do
    %{
      "title" => collection_name,
      "type" => "OCCURRENCE",
      "installationKey" => System.get_env("GBIF_INSTALLATION_KEY"),
      "publishingOrganizationKey" => System.get_env("GBIF_ORGANIZATION_KEY"),
      "language" => "eng"
    }
  end

  def create_endpoint(file_url, registration) do
    Req.post(
      url: "#{System.get_env("GBIF_DATASET_URL")}/#{registration}/endpoint",
      auth: gbif_auth(),
      json: endpoint_params(file_url)
    )
  end

  defp endpoint_params(file_url) do
    %{
      "type" => "DWC_ARCHIVE",
      "url" => file_url
    }
  end

  defp gbif_auth, do: {:basic, "#{System.get_env("GBIF_USER")}:#{System.get_env("GBIF_PASSWORD")}"}
end
