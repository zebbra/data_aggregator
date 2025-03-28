defmodule DataAggregatorApi.HelpersTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.RecordsFixtures

  doctest DataAggregatorApi.Router, import: true

  Mimic.copy(DataAggregator.Records.Validation.Changes.ValidateRecords)
  Mimic.copy(DataAggregator.Records.Validation.Changes.SetCount)

  @doc """
  Setup a collection for testing.
  """
  @spec setup_collection() :: Collection.t()
  def setup_collection do
    setup_collection(%{})
  end

  @spec setup_collection(map()) :: Collection.t()
  def setup_collection(custom_attributes) do
    %{
      name: "Test Collection #{Ecto.UUID.generate()}",
      grscicoll_reference: Ecto.UUID.generate()
    }
    |> Map.merge(custom_attributes)
    |> RecordsFixtures.collection_fixture()
  end
end
