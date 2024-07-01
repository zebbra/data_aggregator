defmodule DataAggregator.Test.DummyDomain do
  @moduledoc false
  use Ash.Domain,
    validate_config_inclusion?: false

  resources do
    resource DataAggregator.Test.User
  end
end
