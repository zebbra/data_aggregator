defmodule DataAggregator.Api.Helpers do
  @moduledoc """
  Helper functions for the Data Aggregator API and clients
  """

  @spec grscicoll_api_base_url() :: String.t()
  def grscicoll_api_base_url do
    case System.get_env("GRSCICOLL_API_BASE_URL") do
      nil -> raise "GRSCICOLL_API_BASE_URL is not set"
      url -> url
    end
  end

  @spec gbif_api_base_url() :: String.t()
  def gbif_api_base_url, do: System.get_env("GBIF_API_BASE_URL")

  @spec gbif_auth() :: {:basic, String.t()}
  def gbif_auth, do: {:basic, "#{System.get_env("GBIF_USER")}:#{System.get_env("GBIF_PASSWORD")}"}

  @spec infospecies_api_base_url() :: String.t()
  def infospecies_api_base_url, do: System.get_env("INFOSPECIES_API_BASE_URL")

  @spec create_endpoint_url(String.t()) :: String.t()
  def create_endpoint_url(registration) do
    gbif_api_base_url() <> "/dataset/#{registration}/endpoint"
  end

  @spec register_dataset_url() :: String.t()
  def register_dataset_url do
    gbif_api_base_url() <> "/dataset"
  end

  @spec get_dataset_url(String.t()) :: String.t()
  def get_dataset_url(dataset_key) do
    gbif_api_base_url() <> "/dataset/#{dataset_key}"
  end

  @spec search_occurrence_url() :: String.t()
  def search_occurrence_url do
    gbif_api_base_url() <> "/occurrence/search"
  end

  @spec grscicoll_entity_by_key_url(String.t(), atom()) :: String.t()
  def grscicoll_entity_by_key_url(key, :collection) do
    grscicoll_api_base_url() <> "/collection/#{key}"
  end

  def grscicoll_entity_by_key_url(key, :institution) do
    grscicoll_api_base_url() <> "/institution/#{key}"
  end

  def grscicoll_entity_by_key_url(key, :dataset) do
    gbif_api_base_url() <> "/dataset/#{key}"
  end

  @spec grscicoll_entities_url(atom()) :: String.t()
  def grscicoll_entities_url(:collection) do
    grscicoll_api_base_url() <> "/collection"
  end

  def grscicoll_entities_url(:institution) do
    grscicoll_api_base_url() <> "/institution"
  end

  @spec infospecies_validation_notification_url() :: String.t()
  def infospecies_validation_notification_url do
    infospecies_api_base_url() <> "/validation/notification"
  end
end
