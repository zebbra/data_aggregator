alias DataAggregator.Gbif.RestApi
alias DataAggregator.Records.Collection
alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter], exclude: [pending: true])

Mimic.copy(SwissSpecies)
Mimic.copy(RestApi)
Mimic.copy(Collection)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(DataAggregator.Repo, :manual)

# Delete storage files after all tests
ExUnit.after_suite(fn _res -> File.rm_rf("priv/storage/test") end)
