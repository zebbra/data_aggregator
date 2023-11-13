ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(DataAggregator.Repo, :manual)

# Delete storage files after all tests
ExUnit.after_suite(fn _res -> File.rm_rf("priv/storage/test") end)
