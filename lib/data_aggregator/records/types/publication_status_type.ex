defmodule DataAggregator.Records.PublicationStatusType do
  @moduledoc """
  Enum to define the states a record can be in for publication.

  `:published` means the record was handed to GBIF as part of a published archive - not that
  GBIF confirmed the occurrence exists. See `docs/adr/0001-publication-is-asserted-not-verified.md`.

  `:in_publication` is retired: nothing sets it any more, but historical paper trail versions
  still carry it and have to keep rendering, so the value must stay in this enum.
  """

  use Ash.Type.Enum,
    values: [
      :not_published,
      :publishing,
      # retired - never set again, kept so historical versions still render
      :in_publication,
      :published,
      :publication_failed,
      :stale
    ]
end
