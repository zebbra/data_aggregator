defmodule DataAggregator.Accounts.Changes.AcceptTermsChange do
  @moduledoc """
  Change to accept terms.
  """
  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.change_attribute(changeset, :terms_accepted_at, DateTime.utc_now())
  end
end
