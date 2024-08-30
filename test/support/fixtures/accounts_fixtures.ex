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

  @default_admin %User{
    first_name: "Admin",
    roles: ["admin"],
    email: "admin@example.com",
    hashed_password: "secret42"
  }

  def default_admin do
    @default_admin
  end

  def default_admin_map do
    @default_admin
    |> Map.from_struct()
    |> Map.take([:id, :roles, :institution_id])
  end

  @doc """
  Generate a user
  """
  def user_fixture(attrs \\ %{}) do
    @user_defaults
    |> Map.merge(attrs)
    |> User.register_with_password!()
  end
end
