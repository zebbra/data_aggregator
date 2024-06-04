defmodule DataAggregator.Api.Helpers do
  @moduledoc """
  Helper functions for the Data Aggregator API and clients
  """

  @spec gbif_base_url() :: String.t()
  def gbif_base_url, do: System.get_env("GBIF_API_BASE_URL")

  @spec gbif_auth() :: {:basic, String.t()}
  def gbif_auth, do: {:basic, "#{System.get_env("GBIF_USER")}:#{System.get_env("GBIF_PASSWORD")}"}

  @spec create_endpoint_url(String.t()) :: String.t()
  def create_endpoint_url(registration) do
    gbif_base_url() <> "/dataset/#{registration}/endpoint"
  end

  @spec register_dataset_url() :: String.t()
  def register_dataset_url do
    gbif_base_url() <> "/dataset"
  end

  @spec search_occurrence_url() :: String.t()
  def search_occurrence_url do
    gbif_base_url() <> "/occurrence/search"
  end

  @spec grscicoll_entity_by_key_url(String.t(), atom()) :: String.t()
  def grscicoll_entity_by_key_url(key, kind) do
    case kind do
      :collection -> gbif_base_url() <> "/grscicoll/collection/#{key}"
      :institution -> gbif_base_url() <> "/grscicoll/institution/#{key}"
    end
  end

  @spec grscicoll_entities_url(atom()) :: String.t()
  def grscicoll_entities_url(kind) do
    case kind do
      :collection -> gbif_base_url() <> "/grscicoll/collection"
      :institution -> gbif_base_url() <> "/grscicoll/institution"
    end
  end
end
