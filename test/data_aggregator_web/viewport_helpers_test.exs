defmodule DataAggregatorWeb.ViewportHelpersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Phoenix.Component, only: [assign: 3]

  use DataAggregatorWeb.ViewportHelpers

  test "breakpoints are defined" do
    assert @sm == 640
    assert @md == 768
    assert @lg == 1024
    assert @xl == 1280
    assert @xxl == 1536
  end

  test "displays are defined" do
    assert @display_sm == :display_sm
    assert @display_md == :display_md
    assert @display_lg == :display_lg
    assert @display_xl == :display_xl
    assert @display_xxl == :display_xxl
  end

  test "display_size returns the correct display size" do
    assert display_size(0) == @display_sm
    assert display_size(@sm) == @display_sm
    assert display_size(@md - 1) == @display_sm
    assert display_size(@md) == @display_md
    assert display_size(@lg - 1) == @display_md
    assert display_size(@lg) == @display_lg
    assert display_size(@xl - 1) == @display_lg
    assert display_size(@xl) == @display_xl
    assert display_size(@xxl - 1) == @display_xl
    assert display_size(@xxl) == @display_xxl
    assert display_size(@xxl + 1) == @display_xxl
  end

  test "display_size_sm returns true if the display size is at least @sm" do
    assert display_size_sm(0) == false
    assert display_size_sm(@sm) == true
    assert display_size_sm(@md - 1) == true
    assert display_size_sm(@md) == true
    assert display_size_sm(@lg - 1) == true
    assert display_size_sm(@lg) == true
    assert display_size_sm(@xl - 1) == true
    assert display_size_sm(@xl) == true
    assert display_size_sm(@xxl - 1) == true
    assert display_size_sm(@xxl) == true
    assert display_size_sm(@xxl + 1) == true
  end

  test "display_size_md returns true if the display size is at least @md" do
    assert display_size_md(0) == false
    assert display_size_md(@sm) == false
    assert display_size_md(@md - 1) == false
    assert display_size_md(@md) == true
    assert display_size_md(@lg - 1) == true
    assert display_size_md(@lg) == true
    assert display_size_md(@xl - 1) == true
    assert display_size_md(@xl) == true
    assert display_size_md(@xxl - 1) == true
    assert display_size_md(@xxl) == true
    assert display_size_md(@xxl + 1) == true
  end

  test "display_size_lg returns true if the display size is at least @lg" do
    assert display_size_lg(0) == false
    assert display_size_lg(@sm) == false
    assert display_size_lg(@md - 1) == false
    assert display_size_lg(@md) == false
    assert display_size_lg(@lg - 1) == false
    assert display_size_lg(@lg) == true
    assert display_size_lg(@xl - 1) == true
    assert display_size_lg(@xl) == true
    assert display_size_lg(@xxl - 1) == true
    assert display_size_lg(@xxl) == true
    assert display_size_lg(@xxl + 1) == true
  end

  test "display_size_xl returns true if the display size is at least @xl" do
    assert display_size_xl(0) == false
    assert display_size_xl(@sm) == false
    assert display_size_xl(@md - 1) == false
    assert display_size_xl(@md) == false
    assert display_size_xl(@lg - 1) == false
    assert display_size_xl(@lg) == false
    assert display_size_xl(@xl - 1) == false
    assert display_size_xl(@xl) == true
    assert display_size_xl(@xxl - 1) == true
    assert display_size_xl(@xxl) == true
    assert display_size_xl(@xxl + 1) == true
  end

  test "display_size_xxl returns true if the display size is at least @xxl" do
    assert display_size_xxl(0) == false
    assert display_size_xxl(@sm) == false
    assert display_size_xxl(@md - 1) == false
    assert display_size_xxl(@md) == false
    assert display_size_xxl(@lg - 1) == false
    assert display_size_xxl(@lg) == false
    assert display_size_xxl(@xl - 1) == false
    assert display_size_xxl(@xl) == false
    assert display_size_xxl(@xxl - 1) == false
    assert display_size_xxl(@xxl) == true
    assert display_size_xxl(@xxl + 1) == true
  end

  test "display_size_lt for display_sm always returns false" do
    assert display_size_lt(0, @display_sm) == false
    assert display_size_lt(@sm, @display_sm) == false
    assert display_size_lt(@md - 1, @display_sm) == false
    assert display_size_lt(@md, @display_sm) == false
    assert display_size_lt(@lg - 1, @display_sm) == false
    assert display_size_lt(@lg, @display_sm) == false
    assert display_size_lt(@xl - 1, @display_sm) == false
    assert display_size_lt(@xl, @display_sm) == false
    assert display_size_lt(@xxl - 1, @display_sm) == false
    assert display_size_lt(@xxl, @display_sm) == false
    assert display_size_lt(@xxl + 1, @display_sm) == false
  end

  test "display_size_lt for display_md returns true if the display size is less than the specified size" do
    assert display_size_lt(0, @display_md) == true
    assert display_size_lt(@sm, @display_md) == true
    assert display_size_lt(@md - 1, @display_md) == true
    assert display_size_lt(@md, @display_md) == false
    assert display_size_lt(@lg - 1, @display_md) == false
    assert display_size_lt(@lg, @display_md) == false
    assert display_size_lt(@xl - 1, @display_md) == false
    assert display_size_lt(@xl, @display_md) == false
    assert display_size_lt(@xxl - 1, @display_md) == false
    assert display_size_lt(@xxl, @display_md) == false
    assert display_size_lt(@xxl + 1, @display_md) == false
  end

  test "display_size_lt for display_lg returns true if the display size is less than the specified size" do
    assert display_size_lt(0, @display_lg) == true
    assert display_size_lt(@sm, @display_lg) == true
    assert display_size_lt(@md - 1, @display_lg) == true
    assert display_size_lt(@md, @display_lg) == true
    assert display_size_lt(@lg - 1, @display_lg) == true
    assert display_size_lt(@lg, @display_lg) == false
    assert display_size_lt(@xl - 1, @display_lg) == false
    assert display_size_lt(@xl, @display_lg) == false
    assert display_size_lt(@xxl - 1, @display_lg) == false
    assert display_size_lt(@xxl, @display_lg) == false
    assert display_size_lt(@xxl + 1, @display_lg) == false
  end

  test "display_size_lt for display_xl returns true if the display size is less than the specified size" do
    assert display_size_lt(0, @display_xl) == true
    assert display_size_lt(@sm, @display_xl) == true
    assert display_size_lt(@md - 1, @display_xl) == true
    assert display_size_lt(@md, @display_xl) == true
    assert display_size_lt(@lg - 1, @display_xl) == true
    assert display_size_lt(@lg, @display_xl) == true
    assert display_size_lt(@xl - 1, @display_xl) == true
    assert display_size_lt(@xl, @display_xl) == false
    assert display_size_lt(@xxl - 1, @display_xl) == false
    assert display_size_lt(@xxl, @display_xl) == false
    assert display_size_lt(@xxl + 1, @display_xl) == false
  end

  test "display_size_lt for display_xxl returns true if the display size is less than the specified size" do
    assert display_size_lt(0, @display_xxl) == true
    assert display_size_lt(@sm, @display_xxl) == true
    assert display_size_lt(@md - 1, @display_xxl) == true
    assert display_size_lt(@md, @display_xxl) == true
    assert display_size_lt(@lg - 1, @display_xxl) == true
    assert display_size_lt(@lg, @display_xxl) == true
    assert display_size_lt(@xl - 1, @display_xxl) == true
    assert display_size_lt(@xl, @display_xxl) == true
    assert display_size_lt(@xxl - 1, @display_xxl) == true
    assert display_size_lt(@xxl, @display_xxl) == false
    assert display_size_lt(@xxl + 1, @display_xxl) == false
  end

  test "display_size_gt for display_sm returns true if the display size is greater than the specified size" do
    assert display_size_gt(0, @display_sm) == false
    assert display_size_gt(@sm, @display_sm) == false
    assert display_size_gt(@md - 1, @display_sm) == false
    assert display_size_gt(@md, @display_sm) == true
    assert display_size_gt(@lg - 1, @display_sm) == true
    assert display_size_gt(@lg, @display_sm) == true
    assert display_size_gt(@xl - 1, @display_sm) == true
    assert display_size_gt(@xl, @display_sm) == true
    assert display_size_gt(@xxl - 1, @display_sm) == true
    assert display_size_gt(@xxl, @display_sm) == true
    assert display_size_gt(@xxl + 1, @display_sm) == true
  end

  test "display_size_gt for display_md returns true if the display size is greater than the specified size" do
    assert display_size_gt(0, @display_md) == false
    assert display_size_gt(@sm, @display_md) == false
    assert display_size_gt(@md - 1, @display_md) == false
    assert display_size_gt(@md, @display_md) == false
    assert display_size_gt(@lg - 1, @display_md) == false
    assert display_size_gt(@lg, @display_md) == true
    assert display_size_gt(@xl - 1, @display_md) == true
    assert display_size_gt(@xl, @display_md) == true
    assert display_size_gt(@xxl - 1, @display_md) == true
    assert display_size_gt(@xxl, @display_md) == true
    assert display_size_gt(@xxl + 1, @display_md) == true
  end

  test "display_size_gt for display_lg returns true if the display size is greater than the specified size" do
    assert display_size_gt(0, @display_lg) == false
    assert display_size_gt(@sm, @display_lg) == false
    assert display_size_gt(@md - 1, @display_lg) == false
    assert display_size_gt(@md, @display_lg) == false
    assert display_size_gt(@lg - 1, @display_lg) == false
    assert display_size_gt(@lg, @display_lg) == false
    assert display_size_gt(@xl - 1, @display_lg) == false
    assert display_size_gt(@xl, @display_lg) == true
    assert display_size_gt(@xxl - 1, @display_lg) == true
    assert display_size_gt(@xxl, @display_lg) == true
    assert display_size_gt(@xxl + 1, @display_lg) == true
  end

  test "display_size_gt for display_xl returns true if the display size is greater than the specified size" do
    assert display_size_gt(0, @display_xl) == false
    assert display_size_gt(@sm, @display_xl) == false
    assert display_size_gt(@md - 1, @display_xl) == false
    assert display_size_gt(@md, @display_xl) == false
    assert display_size_gt(@lg - 1, @display_xl) == false
    assert display_size_gt(@lg, @display_xl) == false
    assert display_size_gt(@xl - 1, @display_xl) == false
    assert display_size_gt(@xl, @display_xl) == false
    assert display_size_gt(@xxl - 1, @display_xl) == false
    assert display_size_gt(@xxl, @display_xl) == true
    assert display_size_gt(@xxl + 1, @display_xl) == true
  end

  test "display_size_gt for display_xxl always returns false" do
    assert display_size_gt(0, @display_xxl) == false
    assert display_size_gt(@sm, @display_xxl) == false
    assert display_size_gt(@md - 1, @display_xxl) == false
    assert display_size_gt(@md, @display_xxl) == false
    assert display_size_gt(@lg - 1, @display_xxl) == false
    assert display_size_gt(@lg, @display_xxl) == false
    assert display_size_gt(@xl - 1, @display_xxl) == false
    assert display_size_gt(@xl, @display_xxl) == false
    assert display_size_gt(@xxl - 1, @display_xxl) == false
    assert display_size_gt(@xxl, @display_xxl) == false
    assert display_size_gt(@xxl + 1, @display_xxl) == false
  end
end
