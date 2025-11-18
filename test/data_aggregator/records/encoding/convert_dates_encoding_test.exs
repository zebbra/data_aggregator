defmodule DataAggregator.Records.Encoding.ConvertDatesTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.Record

  @date_fields [
    :eve_event_date,
    :eve_day,
    :eve_month,
    :eve_year,
    :eve_end_of_period_day,
    :eve_end_of_period_month,
    :eve_end_of_period_year
  ]

  describe "convert dates encoding of records with" do
    setup do
      collection = collection_fixture(%{name: "Convert Dates Test Collection"})

      record_fixture_missing_all_dates =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber0"
        })

      record_fixture_invalid_event_date =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber1",
          eve_event_date: "2025-INVALID-01"
        })

      record_fixture_invalid_event_date_range =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber2",
          eve_event_date: "2025-01-01/2025-INVALID-02"
        })

      record_fixture_only_event_date =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber3",
          eve_event_date: "2025-01-01",
          eve_day: nil,
          eve_month: nil,
          eve_year: nil,
          eve_end_of_period_day: nil,
          eve_end_of_period_month: nil,
          eve_end_of_period_year: nil
        })

      record_fixture_only_event_date_range =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber4",
          eve_event_date: "2025-01-01/2025-02-02",
          eve_day: nil,
          eve_month: nil,
          eve_year: nil,
          eve_end_of_period_day: nil,
          eve_end_of_period_month: nil,
          eve_end_of_period_year: nil
        })

      record_fixture_no_event_date =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber5",
          eve_event_date: nil,
          eve_day: 1,
          eve_month: 1,
          eve_year: 2025,
          eve_end_of_period_day: 20,
          eve_end_of_period_month: 1,
          eve_end_of_period_year: 2025
        })

      record_fixture_complete =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber6",
          eve_event_date: "2025-01-01",
          eve_day: 1,
          eve_month: 1,
          eve_year: 2025,
          eve_end_of_period_day: 20,
          eve_end_of_period_month: 1,
          eve_end_of_period_year: 2025
        })

      record_fixture_complete_range =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber7",
          eve_event_date: "2025-01-01/2025-02-02",
          eve_day: 1,
          eve_month: 1,
          eve_year: 2025,
          eve_end_of_period_day: 20,
          eve_end_of_period_month: 1,
          eve_end_of_period_year: 2025
        })

      record_fixture_no_event_date_and_no_period =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber8",
          eve_event_date: nil,
          eve_day: 1,
          eve_month: 1,
          eve_year: 2025,
          eve_end_of_period_day: nil,
          eve_end_of_period_month: nil,
          eve_end_of_period_year: nil
        })

      record_fixture_no_event_date_and_no_start =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalogNumber9",
          eve_event_date: nil,
          eve_day: nil,
          eve_month: nil,
          eve_year: nil,
          eve_end_of_period_day: 20,
          eve_end_of_period_month: 1,
          eve_end_of_period_year: 2025
        })

      [
        collection: collection,
        record_fixture_missing_all_dates: record_fixture_missing_all_dates,
        record_fixture_invalid_event_date: record_fixture_invalid_event_date,
        record_fixture_invalid_event_date_range: record_fixture_invalid_event_date_range,
        record_fixture_only_event_date: record_fixture_only_event_date,
        record_fixture_only_event_date_range: record_fixture_only_event_date_range,
        record_fixture_no_event_date: record_fixture_no_event_date,
        record_fixture_complete: record_fixture_complete,
        record_fixture_complete_range: record_fixture_complete_range,
        record_fixture_no_event_date_and_no_period: record_fixture_no_event_date_and_no_period,
        record_fixture_no_event_date_and_no_start: record_fixture_no_event_date_and_no_start
      ]
    end

    test "encode/2 for :convert_dates catalog - all date values are nil",
         %{
           record_fixture_missing_all_dates: record
         } do
      {:ok, record} = Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      Enum.each(@date_fields, fn date_field ->
        assert Map.get(encoded_record, date_field) == nil
      end)

      assert record.state == :encoded
    end

    test "encode/2 for :convert_dates catalog - invalid event date",
         %{
           record_fixture_invalid_event_date: record
         } do
      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(record, :convert_dates, tenant: record.collection_id) end)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert record.state == :failed

      # set event date to nil, to avoid wrong event_date on the encoding layer
      assert encoded_record.eve_event_date == nil
      assert encoded_record.eve_day == nil
      assert encoded_record.eve_month == nil
      assert encoded_record.eve_year == nil
      assert encoded_record.eve_end_of_period_day == nil
      assert encoded_record.eve_end_of_period_month == nil
      assert encoded_record.eve_end_of_period_year == nil

      assert logs =~
               "Can not populate day, month and year. Could not convert or parse eventDate because of wrong format: \\\"2025-INVALID-01\\\" {:error, :no_match}"
    end

    test "encode/2 for :convert_dates catalog - invalid event date range",
         %{
           record_fixture_invalid_event_date_range: record
         } do
      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(record, :convert_dates, tenant: record.collection_id) end)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert record.state == :failed
      assert encoded_record.eve_event_date == nil
      assert encoded_record.eve_day == nil
      assert encoded_record.eve_month == nil
      assert encoded_record.eve_year == nil
      assert encoded_record.eve_end_of_period_day == nil
      assert encoded_record.eve_end_of_period_month == nil
      assert encoded_record.eve_end_of_period_year == nil

      assert logs =~
               "Can not populate day, month and year. Could not convert or parse eventDate because of wrong format: \\\"2025-01-01/2025-INVALID-02\\\" {:error, :no_match}"
    end

    test "encode/2 for :convert_dates catalog - only event date present",
         %{
           record_fixture_only_event_date: record
         } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == "2025-01-01"
      assert encoded_record.eve_day == 1
      assert encoded_record.eve_month == 1
      assert encoded_record.eve_year == 2025
      assert encoded_record.eve_end_of_period_day == nil
      assert encoded_record.eve_end_of_period_month == nil
      assert encoded_record.eve_end_of_period_year == nil
    end

    test "encode/2 for :convert_dates catalog - only event date range present",
         %{
           record_fixture_only_event_date_range: record
         } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == "2025-01-01/2025-02-02"
      assert encoded_record.eve_day == 1
      assert encoded_record.eve_month == 1
      assert encoded_record.eve_year == 2025
      assert encoded_record.eve_end_of_period_day == 2
      assert encoded_record.eve_end_of_period_month == 2
      assert encoded_record.eve_end_of_period_year == 2025
    end

    test "encode/2 for :convert_dates catalog - only event date missing",
         %{
           record_fixture_no_event_date: record
         } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == "2025-01-01/2025-01-20"
      assert encoded_record.eve_day == 1
      assert encoded_record.eve_month == 1
      assert encoded_record.eve_year == 2025
      assert encoded_record.eve_end_of_period_day == 20
      assert encoded_record.eve_end_of_period_month == 1
      assert encoded_record.eve_end_of_period_year == 2025
    end

    test "encode/2 for :convert_dates catalog - all date values present",
         %{
           record_fixture_complete: record
         } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == "2025-01-01/2025-01-20"
      assert encoded_record.eve_day == 1
      assert encoded_record.eve_month == 1
      assert encoded_record.eve_year == 2025
      assert encoded_record.eve_end_of_period_day == 20
      assert encoded_record.eve_end_of_period_month == 1
      assert encoded_record.eve_end_of_period_year == 2025
    end

    test "encode/2 for :convert_dates catalog - all date values present (date range)", %{
      record_fixture_complete_range: record
    } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == "2025-01-01/2025-01-20"
      assert encoded_record.eve_day == 1
      assert encoded_record.eve_month == 1
      assert encoded_record.eve_year == 2025
      assert encoded_record.eve_end_of_period_day == 20
      assert encoded_record.eve_end_of_period_month == 1
      assert encoded_record.eve_end_of_period_year == 2025
    end

    test "encode/2 for :convert_dates catalog - event date and end of period date missing", %{
      record_fixture_no_event_date_and_no_period: record
    } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == "2025-01-01"
      assert encoded_record.eve_day == 1
      assert encoded_record.eve_month == 1
      assert encoded_record.eve_year == 2025
      assert encoded_record.eve_end_of_period_day == nil
      assert encoded_record.eve_end_of_period_month == nil
      assert encoded_record.eve_end_of_period_year == nil
    end

    test "encode/2 for :convert_dates catalog - event date and start date missing", %{
      record_fixture_no_event_date_and_no_start: record
    } do
      {:ok, record} =
        Record.encode(record, :convert_dates, tenant: record.collection_id)

      record = Ash.load!(record, :encoded_record)
      encoded_record = record.encoded_record

      assert encoded_record.eve_event_date == nil
      assert encoded_record.eve_day == nil
      assert encoded_record.eve_month == nil
      assert encoded_record.eve_year == nil
      assert encoded_record.eve_end_of_period_day == 20
      assert encoded_record.eve_end_of_period_month == 1
      assert encoded_record.eve_end_of_period_year == 2025
    end
  end
end
