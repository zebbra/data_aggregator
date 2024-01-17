defmodule DataAggregator.RecordEncodingResultFixture do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  use ExUnit.Case, async: true
  use Mimic

  alias DataAggregator.Records.Encoding.RecordEncodingResult

  import DataAggregator.RecordsFixtures

  @record_encoding_result_defaults %{
    input: %{
      "tax_taxon_id" => 1234
    },
    output: %{
      "tax_taxon_id_ch" => 5678,
      "tax_accepted_name_usage" => "super accepted name",
      "tax_accepted_name_usage_id" => 1234,
      "tax_scientific_name" => "my scientific name",
      "tax_taxon_rank" => "SPECIES"
    },
    message: nil,
    catalog: :swiss_species,
    state: :success
  }

  def get_default_attrs, do: @record_encoding_result_defaults

  @doc """
    Generate a record_encoding_result.
  """
  def record_encoding_result_fixture(attrs \\ %{}) do
    @record_encoding_result_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:record, fn -> record_fixture() end)
    |> RecordEncodingResult.create!()
  end
end
