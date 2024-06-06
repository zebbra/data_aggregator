defmodule DataAggregator.Records.Import.Workers.EncoderTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder

  describe "DataAggregator.Records.Record.Workers.Encoder.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_gbif_taxonomy_invalid()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "succeeds a valid record to encode", %{
      correct_record: correct_record
    } do
      expect_correct_swiss_species_api_call()

      {:ok, record} = perform_job(Encoder, %{id: correct_record.id})

      assert record.state == :encoded
    end

    # at the moment there is no failing matchType, we accept all results
    @tag :pending
    test "fails an invalid record to encode", %{invalid_record: invalid_record} do
      {_result, logs} = with_log(fn -> perform_job(Encoder, %{id: invalid_record.id}) end)

      record = Record.get_by_id!(invalid_record.id)

      assert record.state == :failed

      assert logs =~
               "For this species name we could not find a matching taxonomy. matchType \\\"HIGHERRANK\\\" is not accepted"
    end
  end
end
