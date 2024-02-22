alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

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

alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesImporter

Enum.map(
  # delete catalog before importing from csv
  SwissSpecies.read_all!(),
  &SwissSpecies.destroy!/1
)

"initialize/catalogs/swiss_species_registry.csv"
|> Path.expand(DataAggregator.priv_dir())
|> Path.wildcard()
|> Enum.each(&SwissSpeciesImporter.import_swiss_species_catalog_from_csv/1)
