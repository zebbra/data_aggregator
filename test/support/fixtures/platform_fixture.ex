defmodule DataAggregator.PlatformFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Platform` context.
  """

  alias DataAggregator.Platform.Institution

  @institution_defaults %{
    name: "Institution A",
    grscicoll_reference: "5b487a79-76ef-4615-93d9-f4ea25a40c33"
  }

  @doc """
  Generate a institution.
  """
  def institution_fixture(attrs \\ %{}) do
    @institution_defaults
    |> Map.merge(attrs)
    |> Institution.create!()
  end
end
