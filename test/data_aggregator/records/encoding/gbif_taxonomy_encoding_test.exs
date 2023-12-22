defmodule DataAggregator.GbifTaxonomyEncodingTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic
  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.Strategy.GbifTaxonomy
  alias DataAggregator.Records.Record

  import DataAggregator.EncodingFixtures

  describe "encoding of records with " do
    setup do
      records = [
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding()
      ]

      [records: records]
    end

    test "encode/1 for :gbif_taxonomy catalog which returns all successful encoded_records", %{
      records: records
    } do
      expect_correct_matching_api_call()
      expect_correct_species_api_call()

      {:ok, encoding_result} = Record.encode(records)

      %{successful_records: successful_records, errors: errors, failed_records: failed_records} =
        encoding_result

      assert Enum.count(successful_records) == 5

      assert Enum.each(successful_records, fn record ->
               encoded_record = EncodedRecord.get_by_record!(record)

               assert encoded_record.tax_family === "Muscicapidae"

               assert encoded_record.tax_scientific_name === "Oenanthe Vieillot, 1816"
             end)

      assert Enum.each(successful_records, fn record ->
               assert record.state === :encoded
             end)

      assert Enum.empty?(errors)
      assert Enum.empty?(failed_records)
    end

    test "encode/1 for :gbif_taxonomy catalog which returns successful encoded_records and errors" do
      records_with_invalid_confidence = [record_fixture_for_encoding_invalid_confidence()]

      expect_invalid_confidence_from_matching_api_call()

      {{:ok, encoding_result}, logs} =
        with_log(fn -> Record.encode(records_with_invalid_confidence) end)

      %{successful_records: successful_records, errors: errors, failed_records: failed_records} =
        encoding_result

      # add more asserts for encoded fields on encoded_record items
      assert Enum.empty?(successful_records) == true
      assert Enum.count(errors) == 1
      assert Enum.count(failed_records) == 1

      assert Enum.each(failed_records, fn failed_record ->
               assert failed_record.state === :encoding_failed
             end)

      assert logs =~ "is not confident (min 80) enough"
    end
  end

  # this mocks the call to the match api --> https://api.gbif.org/v1/species/match
  defp expect_correct_matching_api_call do
    url = GbifTaxonomy.match_api_url()

    expect(Req, :get, fn ^url, [params: [name: "Oenanthea Pallas", kingdom: ""]] ->
      {:ok,
       %{
         status: 200,
         body: correct_match_api_response_body()
       }}
    end)
  end

  # this mocks the call to the species api --> https://api.gbif.org/v1/species/2492483
  # because the response of the matching api above indicates, that the record is a synonym,
  # the accepted species is fetched from the species api and therefore mocked here
  defp expect_correct_species_api_call do
    url = "#{GbifTaxonomy.species_api_url()}/2492483"

    expect(Req, :get, fn ^url, [params: []] ->
      {:ok,
       %{
         status: 200,
         body: correct_species_api_response_body()
       }}
    end)
  end

  # this mocks the call to the match api --> https://api.gbif.org/v1/species/match
  # we expect an incorrect confidence level in the response body
  defp expect_invalid_confidence_from_matching_api_call do
    url = GbifTaxonomy.match_api_url()

    expect(Req, :get, fn ^url, [params: [name: "this leads to wrong confidence", kingdom: ""]] ->
      {:ok,
       %{
         status: 200,
         body: response_body_with_invalid_confidence()
       }}
    end)
  end
end
