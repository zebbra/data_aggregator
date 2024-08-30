defmodule DataAggregator.Accounts.User.Senders.SendPasswordResetEmail do
  @moduledoc """
  Sends a password reset email
  """
  use AshAuthentication.Sender
  use DataAggregatorWeb, :verified_routes

  @impl AshAuthentication.Sender
  def send(user, token, _) do
    DataAggregator.Accounts.Emails.deliver_reset_password_instructions(
      user,
      url(~p"/password-reset/#{token}")
    )
  end
end
