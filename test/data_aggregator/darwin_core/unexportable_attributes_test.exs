defmodule DataAggregator.DarwinCore.UnexportableAttributesTest do
  @moduledoc """
  Guards the attributes we keep on the record but never hand out again.

  `gbifID` was only ever filled by the GBIF API check that used to verify publications. That
  check is gone, so the column would be permanently empty - it must not appear in a published
  archive, a validation file or an export. The stored values are retained on the record.

  See `docs/adr/0001-publication-is-asserted-not-verified.md`.
  """

  use ExUnit.Case, async: true

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Validation.ValidationFile

  @gbif_id_attribute :oth_gbif_id
  @gbif_id_field "gbifID"
  # the Swiss identifier is a different thing and is deliberately left alone
  @gbif_ch_id_field "gbifCHID"

  test "gbifID is listed as unexportable" do
    assert @gbif_id_attribute in Schema.unexportable_attribute_names()
  end

  test "the record keeps the attribute so existing values survive" do
    assert @gbif_id_attribute in Schema.prefixed_attribute_names()
  end

  test "gbifID is in no Darwin Core Archive file" do
    for file_type <- [
          :core,
          :material_sample,
          :preservation,
          :releve,
          :multimedia,
          :distribution,
          :references,
          :permit,
          :species_profile,
          :vernacular_names,
          :chronometric_age,
          :resource_relationship
        ] do
      refute @gbif_id_field in DwcaFile.file_header_fields(file_type)
    end
  end

  test "gbifID is not sent to the InfoSpecies centers for validation" do
    refute @gbif_id_field in ValidationFile.record_headers()
  end

  test "gbifID is not offered as an export column" do
    refute @gbif_id_attribute in Schema.exportable_attribute_names()
    assert :oth_gbif_ch_id in Schema.exportable_attribute_names()
  end

  test "gbifCHID is untouched - it is a different identifier and still goes out" do
    assert @gbif_ch_id_field in ValidationFile.record_headers()
    refute :oth_gbif_ch_id in Schema.unexportable_attribute_names()
    assert :oth_gbif_ch_id in Schema.prefixed_attribute_names()
  end
end
