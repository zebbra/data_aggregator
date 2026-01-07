alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesImporter

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/catalogs/init.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DataAggregator.Repo.insert!(%DataAggregator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistryImporter

# Legacy CSV import for SwissSpecies (kept for backward compatibility)

# delete catalog before importing from csv
DataAggregator.Repo.query!("TRUNCATE TABLE swiss_species")

"initialize/catalogs/swiss_species_registry.csv"
|> Path.expand(DataAggregator.priv_dir())
|> Path.wildcard()
|> Enum.each(&SwissSpeciesImporter.import_swiss_species_catalog_from_csv/1)

# New JSON import for SwissSpeciesRegistry
DataAggregator.Repo.query!("TRUNCATE TABLE swiss_species_registry")

"initialize/catalogs/swiss_species_registry.json"
|> Path.expand(DataAggregator.priv_dir())
|> SwissSpeciesRegistryImporter.import_from_json()
