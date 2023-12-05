Logger.configure(level: :warning)

defmodule Benchmarks do
  defp records(num) do
    Stream.map(
      1..num,
      &%{
        mte_material_entity_id: "id-#{&1}",
        tax_scientific_name: "Item #{&1}",
        extra_attribute: &1
      }
    )
  end

  defp create_import() do
    %{name: "Benchmark Collection", owner: "test", items_to_digitize: 100_000, reviewer: :swiss_bryophytes}
    |> DataAggregator.Records.Collection.create!()
    |> DataAggregator.Records.Import.create!()
  end

  def bulk_import(num) do
    stream = records(num)
    create_import() |> DataAggregator.Records.Record.bulk_import!(stream) |> Stream.run()
  end
end

records =
  Benchee.run(
    %{
      "bulk_import" => &Benchmarks.bulk_import/1
    },
    inputs: %{
      # "1_000 rows" => 1_000,
      # "10_000 rows" => 10_000,
      "100_000 rows" => 100_000
    },
    time: 3,
    memory_time: 2
  )
