defmodule DataAggregator.Accounts.Secrets do
  @moduledoc false
  use AshAuthentication.Secret

  require Logger

  def secret_for([:authentication, :tokens, :signing_secret], DataAggregator.Accounts.User, _, _) do
    case Application.fetch_env(:data_aggregator, DataAggregatorWeb.Endpoint) do
      {:ok, endpoint_config} ->
        secret = Keyword.fetch(endpoint_config, :secret_key_base)

      :error ->
        Logger.info("No secret key base found in endpoint config")

        :error
    end
  end
end
