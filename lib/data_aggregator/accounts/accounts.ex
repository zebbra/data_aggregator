defmodule DataAggregator.Accounts do
  @moduledoc false
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  authorization do
    authorize :when_requested
  end

  resources do
    resource DataAggregator.Accounts.User
    resource DataAggregator.Accounts.Token
  end

  json_api do
    prefix "/api/json"
  end

  @default_env [
    last_terms_update: ~D[2025-01-27]
  ]

  def get_all_env do
    env = Application.get_env(:data_aggregator, __MODULE__, [])
    Keyword.merge(@default_env, env)
  end

  def get_env(key, default \\ nil), do: Keyword.get(get_all_env(), key, default)
  def last_terms_update, do: get_env(:last_terms_update)
end
