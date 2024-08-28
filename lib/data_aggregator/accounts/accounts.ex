defmodule DataAggregator.Accounts do
  @moduledoc false
  use Ash.Domain

  resources do
    resource DataAggregator.Accounts.User
    resource DataAggregator.Accounts.Token
  end
end
