defmodule DataAggregator.Accounts.Token do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    domain: DataAggregator.Accounts

  postgres do
    table "tokens"
    repo DataAggregator.Repo
  end
end
