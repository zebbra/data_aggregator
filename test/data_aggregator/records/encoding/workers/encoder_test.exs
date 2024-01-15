defmodule DataAggregator.Records.Import.Workers.EncoderTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic.DSL

  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder

  import DataAggregator.EncodingFixtures

  describe "DataAggregator.Records.Record.Workers.Encoder.perform/1" do
    setup do
      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_invalid_confidence()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "succeeds a valid record to encode", %{
      correct_record: correct_record
    } do
      # mocking the api calls to the GBIF API
      expect_correct_matching_api_call()
      expect_correct_species_api_call()
      expect_correct_swiss_species_api_call()

      {:ok, record} = perform_job(Encoder, %{id: correct_record.id})

      assert record.state == :encoded
    end

    test "fails an invalid record to encode", %{invalid_record: invalid_record} do
      # mocking the api call to the GBIF API
      expect_invalid_confidence_from_matching_api_call()

      {_result, logs} = with_log(fn -> perform_job(Encoder, %{id: invalid_record.id}) end)

      record = Record.get_by_id!(invalid_record.id)

      assert record.state == :failed

      assert logs =~ "is not confident (min 80) enough"
    end
  end
end
