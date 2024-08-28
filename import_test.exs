alias DataAggregator.Records.Collection
alias DataAggregator.Records.Import
# alias DataAggregator.Records.Record

Application.put_env(:data_aggregator, DataAggregator.Records,
  import_batch_size: 1000,
  import_max_concurrency: 1
  # async_import_progress?: false,
  # execute_async: true
)

path = "test/support/fixtures/files/collection-import-m.csv"

mapping = [
  %{name: "scientificName", mapped_to: "tax_scientific_name"},
  %{name: "materialEntityID", mapped_to: "mte_catalog_number"}
]

Logger.configure(level: :info)

collection =
  Collection.create!(%{
    type: :zoology,
    name: "Test Collection",
    owner: "Max Powers",
    grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
  })

import =
  collection
  |> Import.create_from_path!(path)
  |> Import.update_mapping!(mapping)

# :eprof.start_profiling([self()])

# :fprof.start()
# :fprof.trace([:start, procs: :all])

_ = import |> Import.import!() |> dbg()

# :eprof.stop_profiling()
# :eprof.log("import_test.prof")
# :eprof.analyze(:total, sort: :time)
# :eprof.analyze(:total, filter: [calls: 1, time: 100], sort: :time)

# :fprof.trace(:stop)
# :fprof.profile()
# :fprof.analyse(totals: false, dest: ~c"import_test.prof")

# :fprof.analyse(callers: true, sort: :own, totals: true, details: true, dest: 'import_test.fprof')

# Import.import!(import)
