defmodule DataAggregator.DarwinCore.Schema do
  alias Ash.Resource.Attribute
  alias DataAggregator.DarwinCore.Schema.Category

  import DataAggregatorWeb.Gettext

  @prs_attributes [
    %Attribute{
      name: :contact_point,
      type: :string,
      allow_nil?: true,
      description: "TODO: Add attribute descriptions"
    },
    %Attribute{name: :first_name, type: :string, allow_nil?: true},
    %Attribute{name: :last_name, type: :string, allow_nil?: true},
    %Attribute{name: :date_of_birth, type: :date, allow_nil?: true}
  ]

  @eve_attributes [
    %Attribute{name: :event_date, type: :date, allow_nil?: true},
    %Attribute{name: :day, type: :integer, allow_nil?: true},
    %Attribute{name: :month, type: :integer, allow_nil?: true},
    %Attribute{name: :year, type: :integer, allow_nil?: true},
    %Attribute{name: :end_of_period_day, type: :integer, allow_nil?: true},
    %Attribute{name: :end_of_period_month, type: :integer, allow_nil?: true},
    %Attribute{name: :end_of_period_year, type: :integer, allow_nil?: true}
  ]

  @idf_attributes [
    %Attribute{name: :date_identified, type: :date, allow_nil?: true},
    %Attribute{name: :identified_by, type: :string, allow_nil?: true},
    %Attribute{name: :type_status, type: :string, allow_nil?: true}
  ]

  @ref_attributes [
    %Attribute{name: :bibliographic_citation, type: :string, allow_nil?: true},
    %Attribute{name: :creator, type: :string, allow_nil?: true},
    %Attribute{name: :date, type: :date, allow_nil?: true},
    %Attribute{name: :rights, type: :string, allow_nil?: true},
    %Attribute{name: :source, type: :string, allow_nil?: true},
    %Attribute{name: :title, type: :string, allow_nil?: true},
    %Attribute{name: :relationship_established_date, type: :date, allow_nil?: true}
  ]

  @rrp_attributes [
    %Attribute{name: :relationship_of_resource, type: :string, allow_nil?: true},
    %Attribute{name: :relationship_of_resource_id, type: :string, allow_nil?: true}
  ]

  @tax_attributes [
    %Attribute{name: :kingdom, type: :string, allow_nil?: true},
    %Attribute{name: :phylum, type: :string, allow_nil?: true},
    %Attribute{name: :class, type: :string, allow_nil?: true},
    %Attribute{name: :order, type: :string, allow_nil?: true},
    %Attribute{name: :family, type: :string, allow_nil?: true},
    %Attribute{name: :genus, type: :string, allow_nil?: true},
    %Attribute{name: :scientific_name, type: :string, allow_nil?: false},
    %Attribute{name: :scientific_name_authorship, type: :string, allow_nil?: true},
    %Attribute{name: :infraspecific_epithet, type: :string, allow_nil?: true},
    %Attribute{name: :specific_epithet, type: :string, allow_nil?: true},
    %Attribute{name: :taxon_id, type: :integer, allow_nil?: true},
    %Attribute{name: :taxon_id_ch, type: :integer, allow_nil?: true},
    %Attribute{name: :accepted_name_usage, type: :string, allow_nil?: true},
    %Attribute{name: :accepted_name_usage_id, type: :string, allow_nil?: true},
    %Attribute{name: :taxon_rank, type: :string, allow_nil?: true}
  ]

  @spp_attributes [
    %Attribute{name: :life_stage, type: :string, allow_nil?: true}
  ]

  @loc_attributes [
    %Attribute{name: :continent, type: :string, allow_nil?: true},
    %Attribute{name: :country, type: :string, allow_nil?: true},
    %Attribute{name: :locality, type: :string, allow_nil?: true},
    %Attribute{name: :verbatim_locality, type: :string, allow_nil?: true},
    %Attribute{name: :state_province, type: :string, allow_nil?: true},
    %Attribute{name: :decimal_longitude, type: :float, allow_nil?: true},
    %Attribute{name: :decimal_latitude, type: :float, allow_nil?: true},
    %Attribute{name: :georeference_remarks, type: :string, allow_nil?: true}
  ]

  @occ_attributes [
    %Attribute{name: :recorded_by, type: :string, allow_nil?: true},
    %Attribute{name: :sex, type: :string, allow_nil?: true},
    %Attribute{name: :associated_occurrences, type: :string, allow_nil?: true},
    %Attribute{name: :occurrence_remarks, type: :string, allow_nil?: true}
  ]

  @mte_attributes [
    %Attribute{name: :material_entity_id, type: :string, allow_nil?: false}
  ]

  @mts_attributes [
    %Attribute{name: :material_sample_type, type: :string, allow_nil?: true}
  ]

  @categories [
    %Category{
      name: :prs,
      label: ~t"Person"m,
      description: ~t"Attributes related to a person"m,
      attributes: @prs_attributes
    },
    %Category{
      name: :eve,
      label: ~t"Event"m,
      description: ~t"The circumstances of the extraction"m,
      attributes: @eve_attributes
    },
    %Category{
      name: :idf,
      label: ~t"Identification"m,
      description: ~t"Characteristics of the item"m,
      attributes: @idf_attributes
    },
    %Category{
      name: :ref,
      label: ~t"Reference"m,
      description: ~t"Literature and mentions"m,
      attributes: @ref_attributes
    },
    %Category{
      name: :rrp,
      label: ~t"Resource Relationship"m,
      description: ~t"References to other resources"m,
      attributes: @rrp_attributes
    },
    %Category{
      name: :tax,
      label: ~t"Taxon"m,
      description: ~t"Classification structure of the item"m,
      attributes: @tax_attributes
    },
    %Category{
      name: :spp,
      label: ~t"Species Profile"m,
      description: ~t"Life stage and characteristics of the species"m,
      attributes: @spp_attributes
    },
    %Category{
      name: :loc,
      label: ~t"Location"m,
      description: ~t"Geographical description"m,
      attributes: @loc_attributes
    },
    %Category{
      name: :occ,
      label: ~t"Occurence"m,
      description: ~t"Properties of the recorded observation"m,
      attributes: @occ_attributes
    },
    %Category{
      name: :mte,
      label: ~t"Material Entity"m,
      description: ~t"Distinguishing marks of the specimen"m,
      attributes: @mte_attributes
    },
    %Category{
      name: :mts,
      label: ~t"Material Sample"m,
      description: ~t"Specimens documented (bio)chemical elements"m,
      attributes: @mts_attributes
    }
  ]

  @moduledoc """
  Defines the Darwin Core schema and it's attributes.

  The schema is a map of categories, each category is a list of attributes. The attributes are defined as
  `Ash.Resource.Attribute` structs.

  ## Attributes by Category

  #{DataAggregator.DarwinCore.Schema.Docs.schema_docs(@categories)}
  """

  @doc """
  Returns a map attributes grouped by category.
  """
  @spec categories() :: [Category.t()]
  def categories, do: @categories

  @doc """
  Returns a list of all attributes prefixed with their category name.
  """
  @spec prefixed_attributes() :: [Attribute.t()]
  def prefixed_attributes do
    Enum.flat_map(@categories, &Category.prefixed_attributes/1)
  end

  @doc """
  Returns a list of all mandatory (allow_nil == false) attributes prefixed with their category name.
  """
  @spec mandatory_prefixed_attributes() :: [Attribute.t()]
  def mandatory_prefixed_attributes do
    Enum.filter(prefixed_attributes(), &(&1.allow_nil? == false))
  end

  @doc """
  Returns a list of all optional (allow_nil == true) attributes prefixed with their category name.
  """
  @spec optional_prefixed_attributes() :: [Attribute.t()]
  def optional_prefixed_attributes do
    Enum.filter(prefixed_attributes(), &(&1.allow_nil? == true))
  end

  @doc """
  Returns a list of all attribute names prefixed with their category name.
  """
  @spec prefixed_attribute_names() :: [atom()]
  def prefixed_attribute_names do
    Enum.map(prefixed_attributes(), & &1.name)
  end

  @doc """
  Returns the attributes as options for a select input grouped by category.
  """
  def attribute_options do
    for category <- @categories do
      options =
        for attribute <- category.attributes do
          name =
            if attribute.allow_nil?,
              do: attribute.name,
              else: "#{attribute.name} (required)"

          value = Category.prefixed_attribute_name(category, attribute)

          {name, value}
        end

      category_label = category.description
      {category_label, options}
    end
  end
end
