defmodule Mix.Tasks.DataAggregator.Records.Import do
  @moduledoc """
  Import records from a CSV file.

  ## Options

  * `--file` - The path to the CSV file to import.

  ## Examples

  ```shell
  mix data_aggregator.records.import --file test/support/fixtures/files/dataset-1k.csv
  ```
  """

  @shortdoc "Import records from a CSV file"

  use Mix.Task

  @switches [file: :string]

  @mapping [
    %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
    %{name: "Age", mapped_to: "spp_life_stage"},
    %{name: "Auteur et date ssp", mapped_to: "tax_scientific_name_authorship"},
    %{name: "Autres numéros", mapped_to: "occ_associated_occurrences"},
    %{name: "Collecteur", mapped_to: "occ_recorded_by"},
    %{name: "DAYCOLLECTED", mapped_to: "eve_day"},
    %{name: "ENDOFPERIODDAY", mapped_to: "eve_end_of_period_day"},
    %{name: "ENDOFPERIODMONTH", mapped_to: "eve_end_of_period_month"},
    %{name: "ENDOFPERIODYEAR", mapped_to: "eve_end_of_period_year"},
    %{name: "Espèce", mapped_to: "tax_specific_epithet"},
    %{name: "Famille", mapped_to: "tax_family"},
    %{name: "Genre", mapped_to: "tax_genus"},
    %{name: "LatitudeDecimale", mapped_to: "loc_decimal_latitude"},
    %{name: "Localité", mapped_to: "loc_verbatim_locality"},
    %{name: "LongitudeDecimale", mapped_to: "loc_decimal_longitude"},
    %{name: "MONTHCOLLECTED", mapped_to: "eve_month"},
    %{name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"},
    %{name: "Ordre", mapped_to: "tax_order"},
    %{name: "Parties", mapped_to: "mts_material_sample_type"},
    %{name: "Pays", mapped_to: "loc_country"},
    %{name: "PrecisionGEO", mapped_to: "loc_georeference_remarks"},
    %{name: "Province", mapped_to: "loc_state_province"},
    %{name: "Remarques", mapped_to: "occ_occurrence_remarks"},
    %{name: "Sexe", mapped_to: "occ_sex"},
    %{name: "Sous espèce", mapped_to: "tax_infraspecific_epithet"},
    %{name: "Station", mapped_to: "loc_locality"},
    %{name: "YEARCOLLECTED", mapped_to: "eve_year"}
  ]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    file = opts[:file] || raise("Missing required option `--file`")

    Mix.Task.run("app.start")

    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    collection =
      Collection.create!(%{
        name: "Test Collection #{timestamp}",
        owner: "Example Import",
        reviewer: :swiss_bryophytes
      })

    Mix.shell().info(
      "Creating import from file #{inspect(file)} for collection #{inspect(collection.name)} ..."
    )

    import =
      collection
      |> Import.create_from_path!(file)
      |> Import.update_mapping!(@mapping)

    Mix.shell().info("Importing records ...")

    # :eprof.start_profiling([self()])

    import |> Import.run!()

    # :eprof.stop_profiling()
    # :eprof.analyze(:total, filter: [calls: 10])
  end
end
