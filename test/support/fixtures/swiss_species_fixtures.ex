defmodule DataAggregator.SwissSpeciesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Taxonomy.Catalogs.SwissSpecies` resource.
  """

  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  @swiss_species_defaults %{
    taxon_id_ch: 12_345,
    accepted_name: "Default Accepted Name",
    usage_key: "#{:rand.uniform(100_000)}",
    accepted_usage_key: :rand.uniform(100_000),
    scientific_name: "Default Scientific Name",
    rank: "species",
    center: :vogelwarte
  }

  @doc """
  Generate a swiss_species
  """
  def swiss_species_fixture(attrs \\ %{}) do
    params =
      @swiss_species_defaults
      |> Map.merge(attrs)
      |> Map.update!(:usage_key, fn
        key when is_integer(key) -> key
        _ -> "#{:rand.uniform(100_000)}"
      end)

    SwissSpecies.create!(params)
  end
end
