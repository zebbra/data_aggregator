defmodule DataAggregatorWeb.AuthControllerTest do
  use DataAggregatorWeb.ConnCase

  import DataAggregator.AccountsFixtures

  alias DataAggregator.Accounts.User

  describe "authentication flow" do
    test "sign-in page loads successfully", %{conn: conn} do
      # Test that the sign-in page loads without creating an infinite loop or breaks somehow
      conn = get(conn, ~p"/sign-in")

      # Should return a successful response, not a redirect loop or breaks
      assert html_response(conn, 200) =~ "sign"
    end
  end
end
