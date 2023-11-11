defmodule DataAggregator.Records.Import.MappingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Import.Column
  alias DataAggregator.Records.Import.Mapping

  test "map_params/2" do
    columns = [
      %Column{name: "First Column", type: :string, mapped_to: "col_1"},
      %Column{name: "col_2", type: :string, mapped_to: nil},
      %Column{name: "Third column", type: :string, mapped_to: "col_3"},
      %Column{name: :col_four, type: :string, mapped_to: :col_4}
    ]

    params = %{
      "First Column" => "value 1",
      :col_2 => "value 2",
      "Third column" => "value 3",
      "col_four" => "value 4",
      "col_5" => "value 5"
    }

    mapped = Mapping.map_params(params, columns)

    assert mapped == %{
             "col_1" => "value 1",
             "col_2" => "value 2",
             "col_3" => "value 3",
             "col_4" => "value 4",
             "col_5" => "value 5"
           }
  end
end
