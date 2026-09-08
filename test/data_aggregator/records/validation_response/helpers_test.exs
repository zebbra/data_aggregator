defmodule DataAggregator.Records.ValidationResponse.HelpersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias DataAggregator.Records.Validation.ValidationFile
  alias DataAggregator.Records.ValidationResponse.Helpers

  describe "ignored_headers/2" do
    test "every header we send is ingestable again" do
      # Drift guard: `@denied_headers` is maintained by hand, next to the header allow-list
      # of the validation request. Re-adding a term to the request without taking it off the
      # denylist would silently drop it on ingestion.
      assert Helpers.ignored_headers(ValidationFile.record_headers(), :validated) == []
    end

    test "county is no longer ingested" do
      assert Helpers.ignored_headers(["county"], :validated) == ["county"]
    end

    test "organismID and stateProvince are ingested" do
      assert Helpers.ignored_headers(["organismID", "stateProvince"], :validated) == []
    end

    test "the encoding layer of a request file is not ingested" do
      headers = Enum.map(ValidationFile.record_headers(), &("encoded " <> &1))

      assert Helpers.ignored_headers(headers, :validated) == headers
    end

    test "a not validated file only carries its own three headers" do
      assert Helpers.ignored_headers(
               ["collectionCode", "catalogNumber", "annotation"],
               :not_validated
             ) == []
    end

    test "a not validated file rejects the headers of a request file" do
      assert Helpers.ignored_headers(
               ["collectionCode", "scientificName", "organismID"],
               :not_validated
             ) == [
               "scientificName",
               "organismID"
             ]
    end
  end

  describe "ignored_header_errors/1" do
    test "returns nothing when no header was ignored" do
      assert Helpers.ignored_header_errors([]) == []
    end

    test "reports the encoding layer as a single entry" do
      assert [encoded_error] =
               Helpers.ignored_header_errors([
                 "encoded scientificName",
                 "encoded county",
                 "encoded organismID"
               ])

      assert encoded_error.field == "encoded *"
      assert encoded_error.message =~ "3 column(s) of the encoding layer were ignored"
    end

    test "reports every other ignored header on its own" do
      assert [encoded_error, county_error, unknown_error] =
               Helpers.ignored_header_errors([
                 "encoded scientificName",
                 "county",
                 "someUnknownColumn"
               ])

      assert encoded_error.field == "encoded *"
      assert county_error.field == "county"
      assert county_error.message == "Column is not part of the validation and was ignored."
      assert unknown_error.field == "someUnknownColumn"
    end
  end

  describe "reject_ignored_headers_from_chunk/2" do
    test "keeps the chunk untouched when nothing is ignored" do
      chunk = {[%{"catalogNumber" => "GBIFCH00993760"}], 0}

      assert Helpers.reject_ignored_headers_from_chunk(chunk, []) == chunk
    end

    test "drops the ignored headers from every row" do
      chunk = {
        [
          %{"catalogNumber" => "GBIFCH00993760", "county" => "Nyon"},
          %{"catalogNumber" => "GBIFCH00993778", "county" => "Nyon"}
        ],
        1
      }

      assert Helpers.reject_ignored_headers_from_chunk(chunk, ["county"]) == {
               [%{"catalogNumber" => "GBIFCH00993760"}, %{"catalogNumber" => "GBIFCH00993778"}],
               1
             }
    end
  end
end
