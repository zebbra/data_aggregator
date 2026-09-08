defmodule DataAggregator.SwissSpeciesRegistryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry` resource.
  """

  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry

  @swiss_species_registry_defaults %{
    taxon_id_ch: "12_345",
    accepted_name_usage: "Accepted Name Usage",
    scientific_name: "Default Scientific Name",
    rank: "species",
    center: :vogelwarte,
    status: "accepted"
  }

  @doc """
  Generate a swiss_species
  """
  def swiss_species_registry_fixture(attrs \\ %{}) do
    params = Map.merge(@swiss_species_registry_defaults, attrs)

    SwissSpeciesRegistry.create!(params)
  end
end
