defmodule DataAggregator.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Accounts` context.
  """

  alias DataAggregator.Accounts.User

  @user_defaults %{
    first_name: "John",
    last_name: "Doe",
    email: "john.doe@example.com",
    password: "secret42"
  }

  @doc """
  Generate a user
  """
  def user_fixture(attrs \\ %{}) do
    @user_defaults
    |> Map.merge(attrs)
    |> User.register_with_password!()
  end
end
