defmodule DataAggregator.GbifIUCNRedlistEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.IUCN
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "encoding of records with " do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(IUCN.RestAPI, IUCN.RestAPIStub)

      extincted_record = record_fixture_for_encoding_iucn_redlist_extinct()
      not_evaluated_record = record_fixture_for_encoding_iucn_redlist_not_evaluated()

      [
        extincted_record: extincted_record,
        not_evaluated_record: not_evaluated_record
      ]
    end

    test "encode/2 for :iucn_redlist catalog which identified an vulnerable species", %{
      extincted_record: record
    } do
      {:ok, record} = Record.encode(record, :iucn_redlist, tenant: record.collection_id)

      assert record !== nil

      assert {:ok, encoded_record} =
               EncodedRecord.get_by_record(record.id, tenant: record.collection_id)

      assert {:ok, record} =
               Record.get_by_id(record.id, load: [:iucn_redlist], tenant: record.collection_id)

      assert encoded_record.iucn_redlist_category === "VU"

      # as via migration DataAggregator.Repo.Migrations.RecreateIucnRedlistGeneratedColumnsOnEncodedRecords
      #  configured only 'EX', 'EW', 'RE', 'CR', 'EN' are threated as redlisted
      assert record.iucn_redlist === false

      assert record.state === :encoded
    end

    @tag capture_log: true
    test "encode/2 for :iucn_redlist catalog which identified an unknown species", %{
      not_evaluated_record: record
    } do
      {:ok, record} = Record.encode(record, :iucn_redlist, tenant: record.collection_id)

      assert record !== nil

      assert {:ok, encoded_record} =
               EncodedRecord.get_by_record(record.id, tenant: record.collection_id)

      assert {:ok, record} =
               Record.get_by_id(record.id, load: [:iucn_redlist], tenant: record.collection_id)

      assert encoded_record.iucn_redlist_category === nil
      assert record.iucn_redlist === nil

      assert record.state === :failed
    end

    @tag capture_log: true
    test "encode/2 for :iucn_redlist catalog fails if taxon_id is not provided", %{
      not_evaluated_record: record
    } do
      record = update_record_fixtures!(record, %{tax_genus: nil, tax_specific_epithet: nil})

      {{:ok, record}, logs} =
        with_log(fn ->
          Record.encode(record, :iucn_redlist, tenant: record.collection_id)
        end)

      assert record.state === :failed

      assert logs =~
               "tax_genus and tax_specific_epithet are required to fetch IUCN Red List category"
    end
  end
end
