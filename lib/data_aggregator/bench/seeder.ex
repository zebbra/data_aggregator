defmodule DataAggregator.Bench.Seeder do
  @moduledoc """
  Bench-specific seed helpers.

  `bulk_seed!/3` bulk-creates records directly (skipping the CSV import and
  encoder pipelines) to produce a database shaped like "N imported records
  that have been encoded and are fit for validation". Records are created
  with the post-encoding fields set (`loc_country_code`, `tax_kingdom`,
  `oth_swiss_species_registered`, …); `EncodedRecord`s are materialised by
  `CreateEncodedRecordAfterAction` on the create action; and the
  `SwissSpeciesRegistry` is populated with every distinct scientific name so
  the validation filter matches.

  `ensure_dataset!/1` writes a matching CSV to `bench/datasets/` so an import
  scenario can measure the real CSV → Record pipeline against the same count.
  """

  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters
  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry

  require Logger

  @datasets_dir "bench/datasets"

  # number of distinct scientific names used in the seed (records round-robin over them)
  @distinct_species 100

  def ensure_dataset!(count) do
    File.mkdir_p!(@datasets_dir)
    path = Path.join(@datasets_dir, "dataset-#{count}.csv")

    if !File.exists?(path) do
      Logger.info("generating #{path}")

      1..count
      |> Stream.map(&record_row/1)
      |> CSV.encode(headers: true)
      |> Stream.into(File.stream!(path))
      |> Stream.run()
    end

    path
  end

  @doc """
  Bulk-create `count` records in `collection` with the post-encoding shape
  required by the validate / publish / export / validation_response scenarios.

  Creates:
    * `count` Records (which triggers `CreateEncodedRecordAfterAction`, so
      matching EncodedRecords are produced automatically)
    * `SwissSpeciesRegistry` entries for every distinct scientific name,
      round-robined across Infospecies centers (required by
      `StartValidations`)
  """
  def bulk_seed!(collection, user, count) do
    Logger.info("bulk_seed: #{count} records")

    1..count
    |> Stream.map(&record_params(&1, collection))
    |> Ash.bulk_create!(Record, :create,
      actor: user,
      tenant: collection,
      authorize?: false,
      return_records?: false,
      return_errors?: true,
      batch_size: 200
    )

    seed_swiss_species_registry!(count)

    :ok
  end

  defp seed_swiss_species_registry!(count) do
    centers = InfospeciesCenters.get_center_names()
    n = min(count, @distinct_species)

    params =
      for i <- 0..(n - 1) do
        name = scientific_name(i)

        %{
          scientific_name: name,
          taxon_id_ch: "BENCH_#{i}",
          accepted_name_usage: name,
          rank: "species",
          center: Enum.at(centers, rem(i, length(centers))),
          status: "accepted"
        }
      end

    Ash.bulk_create!(params, SwissSpeciesRegistry, :create,
      return_records?: false,
      return_errors?: false,
      batch_size: 500,
      upsert?: true,
      upsert_fields: [:center, :taxon_id_ch, :accepted_name_usage, :rank, :status]
    )
  end

  defp record_params(index, collection) do
    %{
      collection: collection,
      mte_catalog_number: "GEN.#{index}",
      tax_kingdom: "Animalia",
      tax_phylum: "Chordata",
      tax_class: "Mammalia",
      tax_order: "Pilosa",
      tax_family: "Bradypodidae",
      tax_genus: "Bradypus",
      tax_specific_epithet: "tridactylus",
      tax_infraspecific_epithet: "cuculliger",
      tax_scientific_name: scientific_name(rem(index - 1, @distinct_species)),
      tax_scientific_name_authorship: "Wagler, 1831",
      mte_recorded_by: "Dr Gosse",
      org_sex: "F.",
      occ_occurrence_remarks: "bench record",
      mts_material_sample_type: "Peau+crâne",
      loc_country: "Switzerland",
      loc_country_code: "CH",
      loc_verbatim_locality: "Amérique du Sud",
      loc_decimal_latitude: -13.0,
      loc_decimal_longitude: -59.0,
      loc_georeference_remarks: "2 pays seulement",
      oth_swiss_species_registered: true
    }
  end

  defp scientific_name(i), do: "Recordus Examplaris #{i}"

  defp record_row(index) do
    %{
      "Numéro scientifique GBIF" => "GEN.#{index}",
      "Scientific Name" => "Recordus Examplaris #{rem(index - 1, @distinct_species)}",
      "Age" => "",
      "Auteur et date ssp" => "Wagler, 1831",
      "Autres numéros" => "",
      "Collecteur" => "Dr Gosse",
      "DAYCOLLECTED" => "",
      "ENDOFPERIODDAY" => "",
      "ENDOFPERIODMONTH" => "",
      "ENDOFPERIODYEAR" => "",
      "Espèce" => "tridactylus",
      "Famille" => "Bradypodidae",
      "Genre" => "Bradypus",
      "LatitudeDecimale" => "-13",
      "Localité" => "Amérique du Sud",
      "LongitudeDecimale" => "-59",
      "MONTHCOLLECTED" => "",
      "Ordre" => "Pilosa",
      "Parties" => "Peau+crâne",
      "Pays" => "",
      "PrecisionGEO" => "2 pays seulement",
      "Province" => "",
      "Remarques" => "bench record",
      "Sexe" => "F.",
      "Sous espèce" => "cuculliger",
      "Station" => "",
      "YEARCOLLECTED" => ""
    }
  end
end
