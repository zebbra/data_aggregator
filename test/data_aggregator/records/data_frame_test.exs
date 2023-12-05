defmodule DataAggregator.Records.DataFrameTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.DataFrame

  describe "supported file types" do
    supported_files = [
      "test/support/fixtures/files/museum-dataset-import-example.csv",
      "test/support/fixtures/files/museum-dataset-import-example.tsv",
      "test/support/fixtures/files/museum-dataset-import-example.pqt",
      "test/support/fixtures/files/museum-dataset-import-example.arrow"
    ]

    for file <- supported_files do
      test "from_file/1 can read #{file}" do
        assert {:ok, df} = DataFrame.from_file(unquote(file))

        columns = Explorer.DataFrame.n_columns(df)
        assert columns == 27
      end
    end
  end
end
