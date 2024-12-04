defmodule DataAggregator.Records.PublicationLicenseType do
  @moduledoc """
  Enum to define the license type of a publication.
  """

  use Ash.Type.Enum, values: [:cc0, :cc_by, :cc_by_nc]
end
