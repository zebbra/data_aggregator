# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DataAggregator.Repo.insert!(%DataAggregator.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesImporter

"initialize/catalogs/swiss_species_registry.csv"
|> Path.expand(DataAggregator.priv_dir())
|> Path.wildcard()
|> Enum.each(&SwissSpeciesImporter.import_swiss_species_catalog_from_csv/1)
