defmodule DataAggregator.Accounts.SendMagicLink do
  @moduledoc """
  Sends a magic link
  """
  use AshAuthentication.Sender
  use DataAggregatorWeb, :verified_routes

  @impl AshAuthentication.Sender
  def send(user, token, _) do
    DataAggregator.Accounts.Emails.deliver_magic_link(
      user,
      url(~p"/auth/user/magic_link/?token=#{token}")
    )
  end
end
