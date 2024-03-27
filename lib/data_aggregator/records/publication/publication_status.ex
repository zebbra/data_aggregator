defmodule DataAggregator.Records.Publication.PublicationStatus do
  @moduledoc """
  PublicationStatus which represents the status of a `DataAggregator.Records.Record` Resource for a
  specific channel at a specific time given a optional message.
  """

  defstruct [:channel, :status, message: nil]

  @type t :: %__MODULE__{
          # one of [:fast_track, :approval]
          channel: atom(),
          # one of [:publishing, :in_publication, :published, :publication_failed, :stale]
          status: atom(),
          message: String.t() | nil
        }
end
