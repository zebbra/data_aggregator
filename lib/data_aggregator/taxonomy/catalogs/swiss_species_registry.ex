defmodule DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry do
  @moduledoc """
  Ash resource for the Swiss Species Registry (JSON-based).

  This resource stores data imported from the Swiss Species Registry JSON file.
  It uses `scientific_name` as the primary lookup key for encoding, replacing
  the old CSV-based approach that used `usage_key` (GBIF taxon ID).

  ## Attributes

  - `scientific_name` - The scientific name used as lookup key (primary key)
  - `taxon_id_ch` - The Swiss taxon ID (numeric part from "center:id")
  - `accepted_name_usage` - The accepted name (from usage.label or usage.accepted.name.label)
  - `center` - The data center (infofauna, infoflora, swissbryophytes, etc.)
  - `rank` - The taxonomic rank
  - `status` - The usage status (accepted or synonym)
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Taxonomy,
    extensions: [AshUUID]

  alias __MODULE__

  @type t :: %SwissSpeciesRegistry{}

  attributes do
    uuid_attribute :id, prefix: "ssr", public?: true

    attribute :scientific_name, :string, primary_key?: true, allow_nil?: false, public?: true
    attribute :taxon_id_ch, :string, allow_nil?: true, public?: true
    attribute :accepted_name_usage, :string, allow_nil?: true, public?: true
    attribute :center, :atom, allow_nil?: true, public?: true
    attribute :rank, :string, allow_nil?: true, public?: true
    attribute :status, :string, allow_nil?: true, public?: true

    timestamps public?: true, writable?: false
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_scientific_name, action: :read, get_by: [:scientific_name]
  end

  postgres do
    table "swiss_species_registry"
    repo DataAggregator.Repo
  end
end
