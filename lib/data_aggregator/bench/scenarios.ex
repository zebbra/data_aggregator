defmodule DataAggregator.Bench.Scenarios do
  @moduledoc """
  All bench scenarios. Each `run_<name>/4` returns a measurement map.

  The `@scenarios` table drives `mix bench.run`: the scenario name, the module
  function to invoke, and which snapshot (`empty` or `ready`) to restore
  before the run. `empty` has the bench user + collection but no records;
  `ready` has N bulk-seeded records + encoded records + swiss species.
  """

  alias DataAggregator.Bench
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationResponse

  require Ash.Query
  require Logger

  @timeout to_timeout(hour: 4)
  @datasets_dir "bench/datasets"

  @scenarios %{
    "import" => {:run_import, "empty", [:imports]},
    "encode" => {:run_encode, "ready", [:encoders]},
    "publish" => {:run_publish, "ready", []},
    "validate" => {:run_validate, "ready", [:validation_requests]},
    "export" => {:run_export, "ready", []},
    "validation_response" => {:run_validation_response, "ready", [:validation_responses]}
  }

  @default ~w(import encode publish validate export)

  # CSV column → prefixed-attribute mapping matching `Seeder.ensure_dataset!`.
  @import_mapping [
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
    %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"},
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

  def known, do: Map.keys(@scenarios)
  def defaults, do: @default

  @doc """
  Returns the snapshot file name (without extension) for a scenario + size.
  `empty` is size-independent; `ready` is suffixed with the record count.
  """
  def snapshot_for(name, size) do
    case elem(@scenarios[name], 1) do
      "empty" -> "empty"
      base -> "#{base}-#{size}"
    end
  end

  def run(name, collection, user, size) do
    {fun, _, queues} = Map.fetch!(@scenarios, name)
    apply(__MODULE__, fun, [collection, user, queues, size])
  end

  def run_import(collection, user, queues, size) do
    csv = Path.join(@datasets_dir, "dataset-#{size}.csv")

    if !File.exists?(csv) do
      raise "missing dataset #{csv} — run `mix bench.seed --size #{size}` first"
    end

    Bench.measure(queues, @timeout, fn ->
      collection
      |> Import.create_from_path!(csv, actor: user, tenant: collection)
      |> Import.update_mapping!(@import_mapping, actor: user, tenant: collection)
      |> Import.import!(actor: user, tenant: collection)
    end)
  end

  def run_encode(collection, user, queues, _size) do
    Bench.measure(queues, @timeout, fn ->
      Collection.enqueue_encoding!(collection, %{}, actor: user)
    end)
  end

  def run_publish(collection, user, queues, _size) do
    Logger.info("Starting publication process for collection #{collection.id}")

    pub =
      Publication.create!(
        %{
          name: "bench-publication-#{System.unique_integer([:positive])}",
          records_query: %{},
          collection: collection
        },
        actor: user,
        tenant: collection
      )

    Logger.debug("Created publication #{pub.id} for collection #{collection.id}")

    Bench.measure(queues, @timeout, fn ->
      Collection.publish!(pub, actor: user, tenant: collection)
    end)
  end

  def run_validate(collection, user, queues, _size) do
    Bench.measure(queues, @timeout, fn ->
      Collection.start_validations!(collection, actor: user, tenant: collection)
    end)
  end

  def run_export(collection, user, queues, _size) do
    collection = Ash.load!(collection, [:records_to_export_query], actor: user)

    export =
      Export.create!(
        %{
          name: "bench-export-#{System.unique_integer([:positive])}",
          data_layer: :raw,
          header_source: :custom_selection,
          records_query: collection.records_to_export_query,
          collection: collection
        },
        actor: user,
        tenant: collection
      )

    Bench.measure(queues, @timeout, fn ->
      Collection.export!(export, actor: user, tenant: collection)
    end)
  end

  def run_validation_response(collection, user, queues, _size) do
    csv = ensure_validation_csv(collection, user)

    response =
      csv
      |> ValidationResponse.create_from_path!(
        Path.basename(csv),
        %{type: :validated, created_by_id: user.id},
        actor: user
      )
      |> ValidationResponse.add_affected_collection!(collection, actor: user)

    Bench.measure(queues, @timeout, fn ->
      ValidationResponse.enqueue!(response, %{started_by_id: user.id}, actor: user)
    end)
  end

  defp ensure_validation_csv(collection, user) do
    File.mkdir_p!(@datasets_dir)
    path = Path.join(@datasets_dir, "validated-#{collection.id}.csv")

    if File.exists?(path) and File.stat!(path).size > 0 do
      path
    else
      rows =
        Record
        |> Ash.Query.select([:mte_catalog_number, :tax_scientific_name])
        |> Ash.read!(actor: user, tenant: collection, authorize?: false)
        |> Enum.map(fn r ->
          %{
            "catalogNumber" => r.mte_catalog_number,
            "scientificName" => r.tax_scientific_name || "",
            "collectionCode" => "Z",
            "institutionCode" => "UZH",
            "dateOfValidation" => "2026-01-01"
          }
        end)

      File.write!(
        path,
        rows |> CSV.encode(headers: true) |> Enum.to_list() |> IO.iodata_to_binary()
      )

      path
    end
  end
end
