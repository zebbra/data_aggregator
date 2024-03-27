defmodule DataAggregator.Records.Publication.Changes.UpdatePublicationStatus do
  @moduledoc """
  Changeset hook to update a publication status of a record with a given status struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    status = Changeset.get_argument(changeset, :status)

    field = get_field(status[:channel])

    Changeset.change_attribute(changeset, field, status)
  end

  defp get_field(:fast_track), do: :fast_track_status
  defp get_field(:approval), do: :approval_status
  defp get_field(_), do: nil
end
