defmodule DataAggregator.Records.Record.Calculations.IucnRedlistCategoryGroupTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Record.Calculations.IucnRedlistCategoryGroup

  describe "calculate/3" do
    test "returns 'threatened' for VU category" do
      record = %{encoded_record: %{iucn_redlist_category: "VU"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["threatened"]
    end

    test "returns 'threatened' for CR category" do
      record = %{encoded_record: %{iucn_redlist_category: "CR"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["threatened"]
    end

    test "returns 'threatened' for EN category" do
      record = %{encoded_record: %{iucn_redlist_category: "EN"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["threatened"]
    end

    test "returns 'less_threatened' for LC category" do
      record = %{encoded_record: %{iucn_redlist_category: "LC"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["less_threatened"]
    end

    test "returns 'less_threatened' for NT category" do
      record = %{encoded_record: %{iucn_redlist_category: "NT"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["less_threatened"]
    end

    test "returns 'extinct' for EW category" do
      record = %{encoded_record: %{iucn_redlist_category: "EW"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["extinct"]
    end

    test "returns 'extinct' for EX category" do
      record = %{encoded_record: %{iucn_redlist_category: "EX"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["extinct"]
    end

    test "returns 'extinct' for RE category" do
      record = %{encoded_record: %{iucn_redlist_category: "RE"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["extinct"]
    end

    test "returns 'uncertain_data' for NE category" do
      record = %{encoded_record: %{iucn_redlist_category: "NE"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["uncertain_data"]
    end

    test "returns 'uncertain_data' for DD category" do
      record = %{encoded_record: %{iucn_redlist_category: "DD"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["uncertain_data"]
    end

    test "returns nil for unknown category" do
      record = %{encoded_record: %{iucn_redlist_category: "UNKNOWN"}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == [nil]
    end

    test "returns nil when iucn_redlist_category is nil" do
      record = %{encoded_record: %{iucn_redlist_category: nil}}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == ["uncertain_data"]
    end

    test "returns nil when encoded_record is nil" do
      record = %{encoded_record: nil}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == [nil]
    end

    test "returns nil when encoded_record is missing" do
      record = %{}
      result = IucnRedlistCategoryGroup.calculate([record], [], %{})
      assert result == [nil]
    end

    test "handles multiple records" do
      records = [
        %{encoded_record: %{iucn_redlist_category: "VU"}},
        %{encoded_record: %{iucn_redlist_category: "LC"}},
        %{encoded_record: %{iucn_redlist_category: "NE"}},
        %{encoded_record: nil}
      ]

      result = IucnRedlistCategoryGroup.calculate(records, [], %{})
      assert result == ["threatened", "less_threatened", "uncertain_data", nil]
    end
  end
end
