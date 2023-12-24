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
      record = record_fixture_for_encoding()
      [record: record]
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the encoded_record", %{
      record: record
    } do
      expect_correct_matching_api_call()
      expect_correct_species_api_call()

      {:ok, encoding_result} = Record.encode(record, :gbif_taxonomy)

      %{encoded_record: encoded_record, error: error, failed_record: failed_record} =
        encoding_result

      assert encoded_record !== nil

      lookedup_encoded_record = EncodedRecord.get_by_record!(encoded_record)

      assert lookedup_encoded_record !== nil
      assert failed_record === nil
      assert error === nil
      assert lookedup_encoded_record.tax_family === "Muscicapidae"
      assert lookedup_encoded_record.tax_scientific_name === "Oenanthe Vieillot, 1816"
      assert encoded_record.state === :encoded
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the failed_record and the error" do
      record_with_invalid_confidence = record_fixture_for_encoding_invalid_confidence()

      expect_invalid_confidence_from_matching_api_call()

      {{:ok, encoding_result}, logs} =
        with_log(fn -> Record.encode(record_with_invalid_confidence, :gbif_taxonomy) end)

      %{encoded_record: encoded_record, error: error, failed_record: failed_record} =
        encoding_result

      assert encoded_record === nil
      assert failed_record !== nil
      assert error !== nil
      assert failed_record.state === :encoding_failed
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
