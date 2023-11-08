defmodule DataAggregator.Data.Record do
  @moduledoc """
  Ash resource representing a record.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Platform.Collection

  @default_limit 15
  def default_limit, do: @default_limit

  attributes do
    uuid_attribute :id, prefix: "rec"

    attribute :import_data, :map
    attribute :extra_data, :map

    # all Person related attributes
    attribute :prs_contact_point, :string
    attribute :prs_first_name, :string
    attribute :prs_last_name, :string
    attribute :prs_date_of_birth, :date

    # all Event related attributes
    attribute :eve_event_date, :date
    attribute :eve_day, :integer
    attribute :eve_month, :integer
    attribute :eve_year, :integer
    attribute :eve_end_of_period_day, :integer
    attribute :eve_end_of_period_month, :integer
    attribute :eve_end_of_period_year, :integer

    # all Identification related attributes
    attribute :idf_date_identified, :date
    attribute :idf_identified_by, :string
    attribute :idf_type_status, :string

    # all Reference related attributes
    attribute :ref_bibliographic_citation, :string
    attribute :ref_creator, :string
    attribute :ref_date, :date
    attribute :ref_rights, :string
    attribute :ref_source, :string
    attribute :ref_title, :string
    attribute :ref_relationship_established_date, :date

    # all RescourceRelationship related attributes
    attribute :rrp_relationship_of_resource, :string
    attribute :rrp_relationship_of_resource_id, :string

    # all Taxon related attributes
    attribute :tax_family, :string
    attribute :tax_scientific_name_authorship, :string
    attribute :tax_order, :string
    attribute :tax_genus, :string
    attribute :tax_infraspecific_epithet, :string
    attribute :tax_specific_epithet, :string

    attribute :tax_scientific_name, :string do
      allow_nil? false
    end

    # all SpeciesProfile related attributes
    attribute :spp_life_stage, :string

    # all Location related attributes
    attribute :loc_continent, :string
    attribute :loc_country, :string
    attribute :loc_locality, :string
    attribute :loc_state_province, :string
    attribute :loc_verbatim_locality, :string
    attribute :loc_decimal_longitude, :float
    attribute :loc_decimal_latitude, :float
    attribute :loc_georeference_remarks, :string

    # all Occurrence related attributes
    attribute :occ_recorded_by, :string
    attribute :occ_sex, :string
    attribute :occ_associated_occurrences, :string
    attribute :occ_occurrence_remarks, :string

    # all MaterialEntity related attributes
    attribute :mte_material_entity_id, :string do
      allow_nil? false
    end

    # all MaterialSample related attributes
    attribute :mts_material_sample_type, :string

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      api DataAggregator.Platform
      allow_nil? false
    end

    has_many :images, DataAggregator.Data.RecordImage

    many_to_many :image_attachments, Attachment do
      api DataAggregator.Files
      through DataAggregator.Data.RecordImage
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
    end
  end

  actions do
    defaults [:update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
      pagination offset?: true, default_limit: @default_limit, countable: true, required?: false
    end

    create :create do
      primary? true
      argument :collection, Collection, allow_nil?: false
      change manage_relationship(:collection, :collection, type: :append)
    end

    create :create_from_params do
      argument :collection, Collection, allow_nil?: false
      argument :params, :map, allow_nil?: false
      change manage_relationship(:collection, :collection, type: :append)
      change DataAggregator.Data.Changes.ExtractAttributes
    end

    update :update_from_params do
      argument :params, :map, allow_nil?: false
      change DataAggregator.Data.Changes.ExtractAttributes
    end
  end

  code_interface do
    define_for DataAggregator.Data
    define :read
    define :create
    define :create_from_params, args: [:collection, :params]
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "records"
    repo DataAggregator.Repo
  end

  identities do
    identity :mte_material_entity_id, [:collection_id, :mte_material_entity_id]
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  graphql do
    type :record

    queries do
      get :get_record, :read
      list :list_records, :read
    end

    mutations do
      update :update_record, :update
      destroy :destroy_record, :destroy
    end
  end

  json_api do
    type "records"

    routes do
      base("/records")

      get(:read)
      index :read
      patch(:update)
      delete(:destroy)
    end
  end
end
