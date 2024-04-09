defmodule DataAggregator.Records.PublicationStatusType do
  @moduledoc """
  Enum to define the states a record can be in for publication.
  """

  use Ash.Type.Enum,
    values: [
      :not_published,
      :publishing,
      :in_publication,
      :published,
      :publication_failed
    ]

  alias __MODULE__

  defstruct []

  @type t :: %PublicationStatusType{}
end
