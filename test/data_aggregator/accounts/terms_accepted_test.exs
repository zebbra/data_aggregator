defmodule DataAggregator.Accounts.TermsAcceptedTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  import DataAggregator.AccountsFixtures, only: [user_fixture: 0]

  alias DataAggregator.Accounts
  alias DataAggregator.Accounts.Calculations.TermsAccepted

  setup do
    Application.put_env(:data_aggregator, Accounts, last_terms_update: ~D[2025-01-28])
    user = user_fixture()

    [user: user]
  end

  describe "Calculating terms accepted" do
    test "last_terms_update reflects env" do
      assert Accounts.last_terms_update() == ~D[2025-01-28]
    end

    test "User fixture has terms accepted", %{user: user} do
      assert user.terms_accepted_at == ~U[2025-01-30 00:00:00Z]
    end

    test "calculation returns true when terms are accepted after last terms update", %{user: user} do
      assert TermsAccepted.calculate([user], nil, nil) == [true]
    end

    test "calculation returns true when terms are accepted same day as last terms update", %{
      user: user
    } do
      Application.put_env(:data_aggregator, Accounts, last_terms_update: ~D[2025-01-30])
      user = Map.put(user, :terms_accepted_at, DateTime.utc_now())

      assert TermsAccepted.calculate([user], nil, nil) == [true]
    end

    test "calculation returns false when terms are accepted before last terms update", %{
      user: user
    } do
      Application.put_env(:data_aggregator, Accounts, last_terms_update: ~U[2025-01-31 00:00:00Z])

      assert TermsAccepted.calculate([user], nil, nil) == [false]
    end
  end
end
