defmodule DataAggregator.Accounts do
  @moduledoc false
  use Ash.Domain

  resources do
    resource DataAggregator.Accounts.User
    resource DataAggregator.Accounts.Token
  end

  authorization do
    authorize :when_requested
  end
end
