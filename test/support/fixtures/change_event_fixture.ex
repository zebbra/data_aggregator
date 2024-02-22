defmodule DataAggregator.ChangeEventFixture do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  use ExUnit.Case, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.ChangeEvent

  @change_event_defaults %{
    value: "new value",
    previous_value: "old value",
    category: :encoding,
    dwc_attribute: :tax_scientific_name
  }

  @doc """
    Generate a change_event.
  """
  def change_event_fixture(attrs \\ %{}) do
    @change_event_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:record, fn -> record_fixture() end)
    |> ChangeEvent.create!()
  end
end
