defmodule DataAggregator.Accounts.Secrets do
  @moduledoc false
  use AshAuthentication.Secret

  def secret_for([:authentication, :tokens, :signing_secret], DataAggregator.Accounts.User, _) do
    case Application.fetch_env(:data_aggregator, DataAggregatorWeb.Endpoint) do
      {:ok, endpoint_config} ->
        Keyword.fetch(endpoint_config, :secret_key_base)

      :error ->
        :error
    end
  end
end
