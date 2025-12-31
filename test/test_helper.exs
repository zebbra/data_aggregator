alias DataAggregator.CatalogOfLife
alias DataAggregator.Gbif
alias DataAggregator.IUCN
alias DataAggregator.Opencage
alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter], exclude: [pending: true])

Mimic.copy(SwissSpecies)
Mimic.copy(Gbif.RestAPI)
Mimic.copy(CatalogOfLife.RestAPI)
Mimic.copy(IUCN.RestAPI)
Mimic.copy(Opencage.RestAPI)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(DataAggregator.Repo, :manual)

# Delete storage files after all tests
ExUnit.after_suite(fn _res -> File.rm_rf("priv/storage/test") end)
