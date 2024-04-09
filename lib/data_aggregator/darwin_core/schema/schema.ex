alias Ash.Resource.Attribute
alias DataAggregator.DarwinCore.Schema.Category

eve_attributes = [
  %{
    dwc_field: "aspect",
    dwc_link: "http://rs.gbif.org/terms/1.0/aspect",
    dwca_file: :releve,
    attribute: %Attribute{name: :aspect, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "coverAlgaeInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverAlgaeInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_algae_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverCryptogamsInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverCryptogamsInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_cryptogams_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverHerbsInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverHerbsInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_herbs_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverLichensInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverLichensInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_lychens_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverLitterInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverLitterInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_litter_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverMossesInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverMossesInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_mosses_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverRockInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverRockInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_rock_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverShrubsInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverShrubsInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_shrubs_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverTotalInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverTotalInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_toal_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverTreesInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverTreesInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_trees_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "coverWaterInPercentage",
    dwc_link: "http://rs.gbif.org/terms/1.0/coverWaterInPercentage",
    dwca_file: :releve,
    attribute: %Attribute{name: :cover_water_in_percentage, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "eventID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/eventID",
    dwca_file: :core,
    attribute: %Attribute{name: :event_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "parentEventID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/parentEventID",
    dwca_file: :core,
    attribute: %Attribute{name: :parent_event_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "fieldNumber",
    dwc_link: "http://rs.tdwg.org/dwc/terms/fieldNumber",
    dwca_file: :core,
    attribute: %Attribute{name: :field_number, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "eventDate",
    dwc_link: "http://rs.tdwg.org/dwc/terms/eventDate",
    dwca_file: :core,
    attribute: %Attribute{name: :event_date, type: :date, allow_nil?: true}
  },
  %{
    dwc_field: "eventTime",
    dwc_link: "http://rs.tdwg.org/dwc/terms/eventTime",
    dwca_file: :core,
    attribute: %Attribute{name: :event_time, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "endDayOfYear",
    dwc_link: "http://rs.tdwg.org/dwc/terms/endDayOfYear",
    dwca_file: :core,
    attribute: %Attribute{name: :end_day_of_year, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "day",
    dwc_link: "http://rs.tdwg.org/dwc/terms/day",
    dwca_file: :core,
    attribute: %Attribute{name: :day, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "month",
    dwc_link: "http://rs.tdwg.org/dwc/terms/month",
    dwca_file: :core,
    attribute: %Attribute{name: :month, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "year",
    dwc_link: "http://rs.tdwg.org/dwc/terms/year",
    dwca_file: :core,
    attribute: %Attribute{name: :year, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimEventDate",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimEventDate",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_event_date, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "habitat",
    dwc_link: "http://rs.tdwg.org/dwc/terms/habitat",
    dwca_file: :core,
    attribute: %Attribute{name: :habitat, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "fieldNotes",
    dwc_link: "http://rs.tdwg.org/dwc/terms/fieldNotes",
    dwca_file: :core,
    attribute: %Attribute{name: :field_notes, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "eventRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/eventRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :event_remarks, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "herbLayerHeightInCentimeters",
    dwc_link: "http://rs.gbif.org/terms/1.0/herbLayerHeightInCentimeters",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :herb_layer_height_in_centimeters,
      type: :integer,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "inclinationInDegrees",
    dwc_link: "http://rs.gbif.org/terms/1.0/inclinationInDegrees",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :inclination_in_degrees,
      type: :integer,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "lichensIdentified",
    dwc_link: "http://rs.gbif.org/terms/1.0/lichensIdentified",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :lichens_identified,
      type: :boolean,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "mossesIdentified",
    dwc_link: "http://rs.gbif.org/terms/1.0/mossesIdentified",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :mosses_identified,
      type: :boolean,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "project",
    dwc_link: "http://rs.gbif.org/terms/1.0/project",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :project,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "syntaxonName",
    dwc_link: "http://rs.gbif.org/terms/1.0/syntaxonName",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :syntaxon_name,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "treeLayerHeightInMeters",
    dwc_link: "http://rs.gbif.org/terms/1.0/treeLayerHeightInMeters",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :tree_layer_height_in_meters,
      type: :integer,
      allow_nil?: true
    }
  },
  %{
    attribute: %Attribute{name: :end_of_period_day, type: :integer, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :end_of_period_month, type: :integer, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :end_of_period_year, type: :integer, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :habitat_code, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :habitat_contact, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :habitat_inclusion, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :habitat_ref, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :influence, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :landscape_structure, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :micro_structure, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :substratum, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :substratum_state, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "samplingProtocol",
    dwc_link: "http://rs.tdwg.org/dwc/terms/samplingProtocol",
    dwca_file: :core,
    attribute: %Attribute{name: :sampling_protocol, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "sampleSizeValue",
    dwc_link: "http://rs.tdwg.org/dwc/terms/sampleSizeValue",
    dwca_file: :core,
    attribute: %Attribute{name: :sample_size_value, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "sampleSizeUnit",
    dwc_link: "http://rs.tdwg.org/dwc/terms/sampleSizeUnit",
    dwca_file: :core,
    attribute: %Attribute{name: :sample_size_unit, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "samplingEffort",
    dwc_link: "http://rs.tdwg.org/dwc/terms/samplingEffort",
    dwca_file: :core,
    attribute: %Attribute{name: :sampling_effort, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "startDayOfYear",
    dwc_link: "http://rs.tdwg.org/dwc/terms/startDayOfYear",
    dwca_file: :core,
    attribute: %Attribute{name: :start_day_of_year, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "shrubLayerHeightInMeters",
    dwc_link: "http://rs.gbif.org/terms/1.0/shrubLayerHeightInMeters",
    dwca_file: :releve,
    attribute: %Attribute{name: :shrub_layer_height_in_meters, type: :float, allow_nil?: true}
  }
]

idf_attributes = [
  %{
    dwc_field: "dateIdentified",
    dwc_link: "http://rs.tdwg.org/dwc/terms/dateIdentified",
    dwc_file: :core,
    attribute: %Attribute{name: :date_identified, type: :date, allow_nil?: true}
  },
  %{
    dwc_field: "identifiedBy",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identifiedBy",
    dwc_file: :core,
    attribute: %Attribute{name: :identified_by, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "typeStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/typeStatus",
    dwc_file: :core,
    attribute: %Attribute{name: :type_status, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "evidenceType",
    dwc_link: "http://rs.tdwg.org/dwc/terms/evidenceType",
    dwc_file: :core,
    attribute: %Attribute{name: :evidence_type, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationQualifier",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationQualifier",
    dwc_file: :core,
    attribute: %Attribute{name: :identification_qualifier, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationReferences",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationReferences",
    dwc_file: :core,
    attribute: %Attribute{name: :identification_reference, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationRemarks",
    dwc_file: :core,
    attribute: %Attribute{name: :identification_remarks, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationVerificationStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationVerificationStatus",
    dwc_file: :core,
    attribute: %Attribute{
      name: :identification_verification_status,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "identifiedByID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identifiedByID",
    dwc_file: :core,
    attribute: %Attribute{
      name: :identified_by_id,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "previousIdentifications",
    dwc_link: "http://rs.tdwg.org/dwc/terms/previousIdentifications",
    dwc_file: :core,
    attribute: %Attribute{
      name: :previous_identifications,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimIdentification",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimIdentification",
    dwc_file: :core,
    attribute: %Attribute{
      name: :verbatim_identification,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_file: nil,
    attribute: %Attribute{
      name: :last_verified_by,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_file: nil,
    attribute: %Attribute{
      name: :last_verified_by_id,
      type: :string,
      allow_nil?: true
    }
  }
]

tax_attributes = [
  %{
    dwc_field: "taxonID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/taxonID",
    dwca_file: :core,
    attribute: %Attribute{name: :taxon_id, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "identifier",
    dwc_link: "http://purl.org/dc/terms/identifier",
    dwca_file: :core,
    attribute: %Attribute{name: :identifier, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "scientificNameID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/scientificNameID",
    dwca_file: :core,
    attribute: %Attribute{name: :scientific_name_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "parentNameUsageID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/parentNameUsageID",
    dwca_file: :core,
    attribute: %Attribute{name: :parent_name_usage_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "parentNameUsage",
    dwc_link: "http://rs.tdwg.org/dwc/terms/parentNameUsage",
    dwca_file: :core,
    attribute: %Attribute{name: :parent_name_usage, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "originalNameUsageID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/originalNameUsageID",
    dwca_file: :core,
    attribute: %Attribute{name: :original_name_usage_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "originalNameUsage",
    dwc_link: "http://rs.tdwg.org/dwc/terms/originalNameUsage",
    dwca_file: :core,
    attribute: %Attribute{name: :original_name_usage, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "nameAccordingToID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/nameAccordingToID",
    dwca_file: :core,
    attribute: %Attribute{name: :name_according_to_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "nameAccordingTo",
    dwc_link: "http://rs.tdwg.org/dwc/terms/nameAccordingTo",
    dwca_file: :core,
    attribute: %Attribute{name: :name_according_to, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "namePublishedInID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/namePublishedInID",
    dwca_file: :core,
    attribute: %Attribute{name: :name_published_in_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "namePublishedIn",
    dwc_link: "http://rs.tdwg.org/dwc/terms/namePublishedIn",
    dwca_file: :core,
    attribute: %Attribute{name: :name_published_in, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "namePublishedInYear",
    dwc_link: "http://rs.tdwg.org/dwc/terms/namePublishedInYear",
    dwca_file: :core,
    attribute: %Attribute{name: :name_published_in_year, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "higherClassification",
    dwc_link: "http://rs.tdwg.org/dwc/terms/higherClassification",
    dwca_file: :core,
    attribute: %Attribute{name: :higher_classification, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "taxonConceptID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/taxonConceptID",
    dwca_file: :core,
    attribute: %Attribute{name: :taxon_concept_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "kingdom",
    dwc_link: "http://rs.tdwg.org/dwc/terms/kingdom",
    dwca_file: :core,
    attribute: %Attribute{name: :kingdom, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "phylum",
    dwc_link: "http://rs.tdwg.org/dwc/terms/phylum",
    dwca_file: :core,
    attribute: %Attribute{name: :phylum, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "superfamily",
    dwc_link: "http://rs.tdwg.org/dwc/terms/superfamily",
    dwca_file: :core,
    attribute: %Attribute{name: :superfamily, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "class",
    dwc_link: "http://rs.tdwg.org/dwc/terms/class",
    dwca_file: :core,
    attribute: %Attribute{name: :class, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "order",
    dwc_link: "http://rs.tdwg.org/dwc/terms/order",
    dwca_file: :core,
    attribute: %Attribute{name: :order, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "family",
    dwc_link: "http://rs.tdwg.org/dwc/terms/family",
    dwca_file: :core,
    attribute: %Attribute{name: :family, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "subfamily",
    dwc_link: "http://rs.tdwg.org/dwc/terms/subfamily",
    dwca_file: :core,
    attribute: %Attribute{name: :subfamily, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "genus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/genus",
    dwca_file: :core,
    attribute: %Attribute{name: :genus, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "subgenus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/subgenus",
    dwca_file: :core,
    attribute: %Attribute{name: :sub_genus, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "tribe",
    dwc_link: "http://rs.tdwg.org/dwc/terms/tribe",
    dwca_file: :core,
    attribute: %Attribute{name: :tribe, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "subTribe",
    dwc_link: "http://rs.tdwg.org/dwc/terms/subTribe",
    dwca_file: :core,
    attribute: %Attribute{name: :sub_tribe, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "scientificName",
    dwc_link: "http://rs.tdwg.org/dwc/terms/scientificName",
    dwca_file: :core,
    attribute: %Attribute{name: :scientific_name, type: :string, allow_nil?: false}
  },
  %{
    dwc_field: "genericName",
    dwc_link: "http://rs.tdwg.org/dwc/terms/genericName",
    dwca_file: :core,
    attribute: %Attribute{name: :generic_name, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "scientificNameAuthorship",
    dwc_link: "http://rs.tdwg.org/dwc/terms/scientificNameAuthorship",
    dwca_file: :core,
    attribute: %Attribute{name: :scientific_name_authorship, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "infragenericEpithet",
    dwc_link: "http://rs.tdwg.org/dwc/terms/infragenericEpithet",
    dwca_file: :core,
    attribute: %Attribute{name: :infrageneric_epithet, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "infraspecificEpithet",
    dwc_link: "http://rs.tdwg.org/dwc/terms/infraspecificEpithet",
    dwca_file: :core,
    attribute: %Attribute{name: :infraspecific_epithet, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "specificEpithet",
    dwc_link: "http://rs.tdwg.org/dwc/terms/specificEpithet",
    dwca_file: :core,
    attribute: %Attribute{name: :specific_epithet, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "cultivarEpithet",
    dwc_link: "http://rs.tdwg.org/dwc/terms/cultivarEpithet",
    dwca_file: :core,
    attribute: %Attribute{name: :cultivar_epithet, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :taxon_id_ch, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "acceptedNameUsage",
    dwc_link: "http://rs.tdwg.org/dwc/terms/acceptedNameUsage",
    dwca_file: :core,
    attribute: %Attribute{name: :accepted_name_usage, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "acceptedNameUsageID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/acceptedNameUsageID",
    dwca_file: :core,
    attribute: %Attribute{name: :accepted_name_usage_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "taxonRank",
    dwc_link: "http://rs.tdwg.org/dwc/terms/taxonRank",
    dwca_file: :core,
    attribute: %Attribute{name: :taxon_rank, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimTaxonRank",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimTaxonRank",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_taxon_rank, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "vernacularName",
    dwc_link: "http://rs.tdwg.org/dwc/terms/vernacularName",
    dwca_file: :core,
    attribute: %Attribute{name: :vernacular_name, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "nomenclaturalCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/nomenclaturalCode",
    dwca_file: :core,
    attribute: %Attribute{name: :nomenclatural_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "taxonomicStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/taxonomicStatus",
    dwca_file: :core,
    attribute: %Attribute{name: :taxonomic_status, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "nomenclaturalStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/nomenclaturalStatus",
    dwca_file: :core,
    attribute: %Attribute{name: :nomenclatural_status, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "taxonRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/taxonRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :taxon_remarks, type: :string, allow_nil?: true}
  }
]

loc_attributes = [
  %{
    dwc_field: "locationID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/locationID",
    dwca_file: :core,
    attribute: %Attribute{name: :location_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "higherGeographyID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/higherGeographyID",
    dwca_file: :core,
    attribute: %Attribute{name: :higher_geography_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "waterBody",
    dwc_link: "http://rs.tdwg.org/dwc/terms/waterBody",
    dwca_file: :core,
    attribute: %Attribute{name: :water_body, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :water_body_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "higherGeography",
    dwc_link: "http://rs.tdwg.org/dwc/terms/higherGeography",
    dwca_file: :core,
    attribute: %Attribute{name: :higher_geography, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "continent",
    dwc_link: "http://rs.tdwg.org/dwc/terms/continent",
    dwca_file: :core,
    attribute: %Attribute{name: :continent, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "islandGroup",
    dwc_link: "http://rs.tdwg.org/dwc/terms/islandGroup",
    dwca_file: :core,
    attribute: %Attribute{name: :island_group, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "island",
    dwc_link: "http://rs.tdwg.org/dwc/terms/island",
    dwca_file: :core,
    attribute: %Attribute{name: :island, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "country",
    dwc_link: "http://rs.tdwg.org/dwc/terms/country",
    dwca_file: :core,
    attribute: %Attribute{name: :country, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "locality",
    dwc_link: "http://rs.tdwg.org/dwc/terms/locality",
    dwca_file: :core,
    attribute: %Attribute{name: :locality, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimLocality",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimLocality",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_locality, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "stateProvince",
    dwc_link: "http://rs.tdwg.org/dwc/terms/stateProvince",
    dwca_file: :core,
    attribute: %Attribute{name: :state_province, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "decimalLongitude",
    dwc_link: "http://rs.tdwg.org/dwc/terms/decimalLongitude",
    dwca_file: :core,
    attribute: %Attribute{name: :decimal_longitude, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "decimalLatitude",
    dwc_link: "http://rs.tdwg.org/dwc/terms/decimalLatitude",
    dwca_file: :core,
    attribute: %Attribute{name: :decimal_latitude, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "county",
    dwc_link: "http://rs.tdwg.org/dwc/terms/county",
    dwca_file: :core,
    attribute: %Attribute{name: :county, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "municipality",
    dwc_link: "http://rs.tdwg.org/dwc/terms/municipality",
    dwca_file: :core,
    attribute: %Attribute{name: :municipality, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "countryCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/countryCode",
    dwca_file: :core,
    attribute: %Attribute{name: :country_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "minimumElevationInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/minimumElevationInMeters",
    dwca_file: :core,
    attribute: %Attribute{name: :minimum_elevation_in_meters, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "maximumElevationInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/maximumElevationInMeters",
    dwca_file: :core,
    attribute: %Attribute{name: :maximum_elevation_in_meters, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimElevation",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimElevation",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_elevation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "verticalDatum",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verticalDatum",
    dwca_file: :core,
    attribute: %Attribute{name: :vertical_datum, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "minimumDepthInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/minimumDepthInMeters",
    dwca_file: :core,
    attribute: %Attribute{name: :minimum_depth_in_meters, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "maximumDepthInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/maximumDepthInMeters",
    dwca_file: :core,
    attribute: %Attribute{name: :maximum_depth_in_meters, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimDepth",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimDepth",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_depth, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "minimumDistanceAboveSurfaceInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/minimumDistanceAboveSurfaceInMeters",
    dwca_file: :core,
    attribute: %Attribute{
      name: :minimum_distance_above_surface_in_meters,
      type: :integer,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "maximumDistanceAboveSurfaceInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/maximumDistanceAboveSurfaceInMeters",
    dwca_file: :core,
    attribute: %Attribute{
      name: :maximum_distance_above_surface_in_meters,
      type: :integer,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "locationAccordingTo",
    dwc_link: "http://rs.tdwg.org/dwc/terms/locationAccordingTo",
    dwca_file: :core,
    attribute: %Attribute{
      name: :location_according_to,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "locationRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/locationRemarks",
    dwca_file: :core,
    attribute: %Attribute{
      name: :location_remarks,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "geodeticDatum",
    dwc_link: "http://rs.tdwg.org/dwc/terms/geodeticDatum",
    dwca_file: :core,
    attribute: %Attribute{
      name: :geodetic_datum,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "coordinateUncertaintyInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/coordinateUncertaintyInMeters",
    dwca_file: :core,
    attribute: %Attribute{
      name: :coordinate_uncertainty_in_meters,
      type: :integer,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "coordinatePrecision",
    dwc_link: "http://rs.tdwg.org/dwc/terms/coordinatePrecision",
    dwca_file: :core,
    attribute: %Attribute{
      name: :coordinate_precision,
      type: :float,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "pointRadiusSpatialFit",
    dwc_link: "http://rs.tdwg.org/dwc/terms/pointRadiusSpatialFit",
    dwca_file: :core,
    attribute: %Attribute{
      name: :point_radius_spatial_fit,
      type: :float,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimCoordinates",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimCoordinates",
    dwca_file: :core,
    attribute: %Attribute{
      name: :verbatim_coordinates,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimLatitude",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimLatitude",
    dwca_file: :core,
    attribute: %Attribute{
      name: :verbatim_latitude,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimLongitude",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimLongitude",
    dwca_file: :core,
    attribute: %Attribute{
      name: :verbatim_longitude,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimCoordinateSystem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimCoordinateSystem",
    dwca_file: :core,
    attribute: %Attribute{
      name: :verbatim_coordinate_system,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimSRS",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimSRS",
    dwca_file: :core,
    attribute: %Attribute{
      name: :verbatim_srs,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "footprintWKT",
    dwc_link: "http://rs.tdwg.org/dwc/terms/footprintWKT",
    dwca_file: :core,
    attribute: %Attribute{
      name: :footprint_wkt,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "footprintSRS",
    dwc_link: "http://rs.tdwg.org/dwc/terms/footprintSRS",
    dwca_file: :core,
    attribute: %Attribute{
      name: :footprint_srs,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "footprintSpatialFit",
    dwc_link: "http://rs.tdwg.org/dwc/terms/footprintSpatialFit",
    dwca_file: :core,
    attribute: %Attribute{
      name: :footprint_spatial_fit,
      type: :float,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "georeferencedBy",
    dwc_link: "http://rs.tdwg.org/dwc/terms/georeferencedBy",
    dwca_file: :core,
    attribute: %Attribute{
      name: :georeferenced_by,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "georeferencedDate",
    dwc_link: "http://rs.tdwg.org/dwc/terms/georeferencedDate",
    dwca_file: :core,
    attribute: %Attribute{
      name: :georeferenced_date,
      type: :date,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "georeferenceProtocol",
    dwc_link: "http://rs.tdwg.org/dwc/terms/georeferenceProtocol",
    dwca_file: :core,
    attribute: %Attribute{
      name: :georeference_protocol,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "georeferenceSources",
    dwc_link: "http://rs.tdwg.org/dwc/terms/georeferenceSources",
    dwca_file: :core,
    attribute: %Attribute{
      name: :georeference_sources,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "georeferenceRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/georeferenceRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :georeference_remarks, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "georeferenceVerificationStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/georeferenceVerificationStatus",
    dwca_file: :core,
    attribute: %Attribute{
      name: :georeference_verification_status,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    attribute: %Attribute{name: :swiss_coordinates_x, type: :float, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :swiss_coordinates_y, type: :float, allow_nil?: true}
  }
]

mte_attributes = [
  %{
    dwc_field: "materialEntityID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/materialEntityID",
    dwca_file: :core,
    attribute: %Attribute{name: :material_entity_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "anatomicalDescription",
    dwc_link: "http://rs.tdwg.org/dwc/terms/anatomicalDescription",
    dwca_file: :core,
    attribute: %Attribute{name: :anatomical_description, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "parentMaterialEntityID",
    dwca_file: :resource_relationship,
    attribute: %Attribute{name: :parent_material_entity_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "partOfOrganism",
    dwca_file: :resource_relationship,
    attribute: %Attribute{name: :part_of_organism, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "postBurialTransportation",
    dwca_file: :core,
    attribute: %Attribute{name: :post_burial_transportation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimLabel",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimLabel",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_label, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preparations",
    dwc_link: "http://rs.tdwg.org/dwc/terms/preparations",
    dwca_file: :core,
    attribute: %Attribute{name: :preparations, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "materialEntityRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/materialEntityRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :material_entity_remarks, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "recordNumber",
    dwc_link: "http://rs.tdwg.org/dwc/terms/recordNumber",
    dwca_file: :core,
    attribute: %Attribute{name: :record_number, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "recordedBy",
    dwc_link: "http://rs.tdwg.org/dwc/terms/recordedBy",
    dwca_file: :core,
    attribute: %Attribute{name: :recorded_by, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "recordedByID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/recordedByID",
    dwca_file: :core,
    attribute: %Attribute{name: :recorded_by_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismQuantity",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismQuantity",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_quantity, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismQuantityType",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismQuantityType",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_quantity_type, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "lifeStage",
    dwc_link: "http://rs.tdwg.org/dwc/terms/lifeStage",
    dwca_file: :core,
    attribute: %Attribute{name: :life_stage, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "reproductiveCondition",
    dwc_link: "http://rs.tdwg.org/dwc/terms/reproductiveCondition",
    dwca_file: :core,
    attribute: %Attribute{name: :reproductive_condition, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "behavior",
    dwc_link: "http://rs.tdwg.org/dwc/terms/behavior",
    dwca_file: :core,
    attribute: %Attribute{name: :behavior, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "occurrenceStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/occurrenceStatus",
    dwca_file: :core,
    attribute: %Attribute{name: :occurrence_status, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "associatedMedia",
    dwc_link: "http://rs.tdwg.org/dwc/terms/associatedMedia",
    dwca_file: :multimedia,
    attribute: %Attribute{name: :associated_media, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "otherCatalogNumbers",
    dwc_link: "http://rs.tdwg.org/dwc/terms/otherCatalogNumbers",
    dwca_file: :core,
    attribute: %Attribute{name: :other_catalog_numbers, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "references",
    dwc_link: "http://purl.org/dc/terms/references",
    dwca_file: :core,
    attribute: %Attribute{name: :references, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "barcodeLabel",
    dwca_file: :core,
    attribute: %Attribute{name: :barcode_label, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "replacementMinerals",
    dwca_file: :core,
    attribute: %Attribute{name: :replacement_minerals, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "permitID",
    dwca_file: :core,
    attribute: %Attribute{name: :permit_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "articulation",
    dwca_file: :core,
    attribute: %Attribute{name: :articulation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "assemblageOrigin",
    dwca_file: :core,
    attribute: %Attribute{name: :assemblage_origin, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "bioerosion",
    dwca_file: :core,
    attribute: %Attribute{name: :bioerosion, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "catalogNumber",
    dwc_link: "http://rs.tdwg.org/dwc/terms/catalogNumber",
    dwca_file: :core,
    attribute: %Attribute{name: :catalog_number, type: :string, allow_nil?: false}
  },
  %{
    dwc_field: "paleoCompleteness",
    dwca_file: :core,
    attribute: %Attribute{name: :paleo_completeness, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "completeness",
    dwca_file: :core,
    attribute: %Attribute{name: :completeness, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "depositionalEnvironmentText",
    dwca_file: :core,
    attribute: %Attribute{name: :depositional_environment_text, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "depositionalEnvironmentType",
    dwca_file: :core,
    attribute: %Attribute{name: :depositional_environment_type, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dnaBankID",
    dwca_file: :core,
    attribute: %Attribute{name: :dna_bank_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dnaStableID",
    dwca_file: :core,
    attribute: %Attribute{name: :dna_stable_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "encrustation",
    dwca_file: :core,
    attribute: %Attribute{name: :encrustation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "extractionTemporaryID",
    dwca_file: :core,
    attribute: %Attribute{name: :extraction_temporary_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "feedingPredationTraces",
    dwca_file: :core,
    attribute: %Attribute{name: :feeding_predation_traces, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "form",
    dwca_file: :core,
    attribute: %Attribute{name: :form, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "gbifDOI",
    dwca_file: :core,
    attribute: %Attribute{name: :gbif_doi, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "matrix",
    dwca_file: :core,
    attribute: %Attribute{name: :matrix, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "mineralization",
    dwca_file: :core,
    attribute: %Attribute{name: :mineralization, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismQuantityMethod",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismQuantity",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_quantity_method, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "orientation",
    dwca_file: :core,
    attribute: %Attribute{name: :orientation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "sampleDesignation",
    dwca_file: :core,
    attribute: %Attribute{name: :sample_designation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "taphonomy",
    dwca_file: :core,
    attribute: %Attribute{name: :taphonomy, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "tissueBankID",
    dwca_file: :core,
    attribute: %Attribute{name: :tissue_bank_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "yearCollectionEntrance",
    dwca_file: :core,
    attribute: %Attribute{name: :year_collection_entrance, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "origColAuthor",
    dwca_file: :core,
    attribute: %Attribute{name: :orig_col_author, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "originalBiominerals",
    dwca_file: :core,
    attribute: %Attribute{name: :original_biominerals, type: :string, allow_nil?: true}
  }
]

mts_attributes = [
  %{
    dwc_field: "materialSampleID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/materialSampleID",
    dwca_file: :core,
    attribute: %Attribute{name: :material_sample_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "materialSampleType",
    dwc_link: "http://data.ggbn.org/schemas/ggbn/terms/materialSampleType",
    dwca_file: :material_sample,
    attribute: %Attribute{name: :material_sample_type, type: :string, allow_nil?: true}
  }
]

gec_attributes = [
  %{
    dwc_field: "geologicalContextID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/geologicalContextID",
    dwca_file: :core,
    attribute: %Attribute{name: :geological_context_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "bed",
    dwc_link: "http://rs.tdwg.org/dwc/terms/bed",
    dwca_file: :core,
    attribute: %Attribute{name: :bed, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "earliestAgeOrLowestStage",
    dwc_link: "http://rs.tdwg.org/dwc/terms/earliestAgeOrLowestStage",
    dwca_file: :core,
    attribute: %Attribute{name: :earliest_age_or_lowest_stage, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "earliestEonOrLowestEonothem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/earliestEonOrLowestEonothem",
    dwca_file: :core,
    attribute: %Attribute{name: :earliest_eon_or_lowest_eonothem, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "earliestEpochOrLowestSeries",
    dwc_link: "http://rs.tdwg.org/dwc/terms/earliestEpochOrLowestSeries",
    dwca_file: :core,
    attribute: %Attribute{name: :earliest_epoch_or_lowest_series, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "earliestEraOrLowestErathem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/earliestEraOrLowestErathem",
    dwca_file: :core,
    attribute: %Attribute{name: :earliest_era_or_lowest_erathem, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "earliestPeriodOrLowestSystem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/earliestPeriodOrLowestSystem",
    dwca_file: :core,
    attribute: %Attribute{
      name: :earliest_period_or_lowest_system,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "latestEonOrHighestEonothem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/latestEonOrHighestEonothem",
    dwca_file: :core,
    attribute: %Attribute{
      name: :latest_eon_or_highest_eonothem,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "latestEraOrHighestErathem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/latestEraOrHighestErathem",
    dwca_file: :core,
    attribute: %Attribute{
      name: :latest_era_or_highest_erathem,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "latestPeriodOrHighestSystem",
    dwc_link: "http://rs.tdwg.org/dwc/terms/latestPeriodOrHighestSystem",
    dwca_file: :core,
    attribute: %Attribute{
      name: :latest_period_or_highest_system,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "latestEpochOrHighestSeries",
    dwc_link: "http://rs.tdwg.org/dwc/terms/latestEpochOrHighestSeries",
    dwca_file: :core,
    attribute: %Attribute{
      name: :latest_epoch_or_highest_series,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "latestAgeOrHighestStage",
    dwc_link: "http://rs.tdwg.org/dwc/terms/latestAgeOrHighestStage",
    dwca_file: :core,
    attribute: %Attribute{
      name: :latest_age_or_highest_stage,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "lowestBiostratigraphicZone",
    dwc_link: "http://rs.tdwg.org/dwc/terms/lowestBiostratigraphicZone",
    dwca_file: :core,
    attribute: %Attribute{
      name: :lowest_biostratigraphic_zone,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "highestBiostratigraphicZone",
    dwc_link: "http://rs.tdwg.org/dwc/terms/highestBiostratigraphicZone",
    dwca_file: :core,
    attribute: %Attribute{
      name: :highest_biostratigraphic_zone,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "lithostratigraphicTerms",
    dwc_link: "http://rs.tdwg.org/dwc/terms/lithostratigraphicTerms",
    dwca_file: :core,
    attribute: %Attribute{
      name: :lithostratigraphic_terms,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "formation",
    dwc_link: "http://rs.tdwg.org/dwc/terms/formation",
    dwca_file: :core,
    attribute: %Attribute{name: :formation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "group",
    dwc_link: "http://rs.tdwg.org/dwc/terms/group",
    dwca_file: :core,
    attribute: %Attribute{name: :group, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "member",
    dwc_link: "http://rs.tdwg.org/dwc/terms/member",
    dwca_file: :core,
    attribute: %Attribute{name: :member, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "placeOfOrigin",
    dwca_file: :core,
    attribute: %Attribute{name: :place_of_origin, type: :string, allow_nil?: true}
  }
]

org_attributes = [
  %{
    dwc_field: "sex",
    dwc_link: "http://rs.tdwg.org/dwc/terms/sex",
    dwca_file: :core,
    attribute: %Attribute{name: :sex, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "establishmentMeans",
    dwc_link: "http://rs.tdwg.org/dwc/terms/establishmentMeans",
    dwca_file: :core,
    attribute: %Attribute{name: :establishment_means, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "degreeOfEstablishment",
    dwc_link: "http://rs.tdwg.org/dwc/terms/degreeOfEstablishment",
    dwca_file: :core,
    attribute: %Attribute{name: :degree_of_establishment, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "pathway",
    dwc_link: "http://rs.tdwg.org/dwc/terms/pathway",
    dwca_file: :core,
    attribute: %Attribute{name: :pathway, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismID",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismName",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismName",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_name, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismScope",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismScope",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_scope, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "organismRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/organismRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :organism_remarks, type: :string, allow_nil?: true}
  }
]

occ_attributes = [
  %{
    dwc_field: "occurrenceID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/occurrenceID",
    dwca_file: :core,
    attribute: %Attribute{name: :occurrence_id, type: :string, allow_nil?: true}
  }
]

pvn_attributes = [
  %{
    dwc_field: "dnaBankInstitution",
    dwca_file: :core,
    attribute: %Attribute{name: :dna_bank_institution, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dnaStorageCode",
    dwca_file: :core,
    attribute: %Attribute{name: :dna_storage_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationAlterationText",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_alteration_text, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationDateBegin",
    dwc_link: "http://data.ggbn.org/schemas/ggbn/terms/preservationDateBegin",
    dwca_file: :preservation,
    attribute: %Attribute{name: :preservation_date_begin, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationID",
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationMethod",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_method, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationModeKeywords",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_mode_keywords, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationModeText",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_mode_text, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationQuality",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_quality, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationSpecialMode",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_special_mode, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationTemperature",
    dwca_file: :preservation,
    attribute: %Attribute{name: :preservation_temperature, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "sequence",
    dwc_link: "http://data.ggbn.org/schemas/ggbn/terms/preservationTemperature",
    dwca_file: :preservation,
    attribute: %Attribute{name: :sequence, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationType",
    dwca_file: :core,
    attribute: %Attribute{name: :preservation_type, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "storageName",
    dwc_link: "http://data.ggbn.org/schemas/ggbn/terms/sequence",
    dwca_file: :core,
    attribute: %Attribute{name: :storage_name, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "tissueBankInstitution",
    dwca_file: :core,
    attribute: %Attribute{name: :tissue_bank_institution, type: :string, allow_nil?: true}
  }
]

oth_attributes = [
  %{
    dwc_field: "accessRights",
    dwc_link: "http://purl.org/dc/terms/accessRights",
    dwca_file: :core,
    attribute: %Attribute{name: :access_rights, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "basisOfRecord",
    dwc_link: "http://rs.tdwg.org/dwc/terms/basisOfRecord",
    dwca_file: :core,
    attribute: %Attribute{name: :basis_of_record, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "bibliographicCitation",
    dwc_link: "http://purl.org/dc/terms/bibliographicCitation",
    dwca_file: :core,
    attribute: %Attribute{name: :bibliographic_citation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "collectionCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/collectionCode",
    dwca_file: :core,
    attribute: %Attribute{name: :collection_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "collectionID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/collectionID",
    dwca_file: :core,
    attribute: %Attribute{name: :collection_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dataGeneralizations",
    dwc_link: "http://rs.tdwg.org/dwc/terms/dataGeneralizations",
    dwca_file: :core,
    attribute: %Attribute{name: :data_generalizations, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "datasetID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/datasetID",
    dwca_file: :core,
    attribute: %Attribute{name: :dataset_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "datasetName",
    dwc_link: "http://rs.tdwg.org/dwc/terms/datasetName",
    dwca_file: :core,
    attribute: %Attribute{name: :dataset_name, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :date_available, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "informationWithheld",
    dwc_link: "http://rs.tdwg.org/dwc/terms/informationWithheld",
    dwca_file: :core,
    attribute: %Attribute{name: :information_withheld, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "institutionCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/institutionCode",
    dwca_file: :core,
    attribute: %Attribute{name: :institution_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "institutionID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/institutionID",
    dwca_file: :core,
    attribute: %Attribute{name: :institution_id, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :language, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "license",
    dwc_link: "http://rs.tdwg.org/dwc/terms/license",
    dwca_file: :core,
    attribute: %Attribute{name: :license, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :modified_by, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "ownerInstitutionCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/ownerInstitutionCode",
    dwca_file: :core,
    attribute: %Attribute{name: :owner_institution_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "rightsHolder",
    dwc_link: "http://purl.org/dc/terms/rightsHolder",
    dwca_file: :core,
    attribute: %Attribute{name: :rights_holder, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "type",
    dwc_link: "http://purl.org/dc/terms/type",
    dwca_file: :core,
    attribute: %Attribute{name: :type, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :specify_person, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :specify_organism_name, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :specify_locality, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :specify_event, type: :string, allow_nil?: true}
  },
  %{
    attribute: %Attribute{name: :specify_author_of_record, type: :string, allow_nil?: true}
  }
]

ext_attributes = [
  %{
    dwca_file: :amplification,
    attribute: %Attribute{name: :amplification, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :extended_measurement_or_facts,
    attribute: %Attribute{name: :assertions, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :chronometric_age,
    attribute: %Attribute{name: :chronometric, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :permit,
    attribute: %Attribute{name: :permit, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :resource_relationship,
    attribute: %Attribute{name: :resource_relationship, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :references,
    attribute: %Attribute{name: :references, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :distribution,
    attribute: %Attribute{name: :species_distribution, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :species_profile,
    attribute: %Attribute{name: :species_profile, type: :map, allow_nil?: true}
  },
  %{
    dwca_file: :vernacular_names,
    attribute: %Attribute{name: :vernacular_names, type: :map, allow_nil?: true}
  }
]

# not used yet
# cma_attributes = [
#   %{
#     dwc_field: "chronometricAgeConversionProtocol",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeConversionProtocol",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_conversion_protocol,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeDeterminedBy",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeDeterminedBy",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_determined_by,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeDeterminedDate",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeDeterminedDate",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_determined_date,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeProtocol",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeProtocol",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_protocol,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeReferences",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeReferences",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_references,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeRemarks",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeRemarks",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_remarks,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeUncertaintyInYears",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeUncertaintyInYears",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_uncertainty_in_years,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "chronometricAgeUncertaintyMethod",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/chronometricAgeUncertaintyMethod",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :chronometric_age_uncertainty_method,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "earliestChronometricAge",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/earliestChronometricAge",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :earliest_chronometric_age,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "earliestChronometricAgeReferenceSystem",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/earliestChronometricAgeReferenceSystem",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :earliest_chronometric_age_reference_system,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "latestChronometricAge",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/latestChronometricAge",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :latest_chronometric_age,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "latestChronometricAgeReferenceSystem",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/latestChronometricAgeReferenceSystem",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :latest_chronometric_age_reference_system,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "materialDated",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/materialDated",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :material_dated,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "materialDatedID",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/materialDatedID",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :material_dated_id,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "materialDatedRelationship",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/materialDatedRelationship",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :material_dated_relationship,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "uncalibratedChronometricAge",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/uncalibratedChronometricAge",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :uncalibrated_chronometric_age,
#       type: :string,
#       allow_nil?: true
#     }
#   },
#   %{
#     dwc_field: "verbatimChronometricAge",
#     dwc_link: "http://rs.tdwg.org/chrono/terms/verbatimChronometricAge",
#     dwca_file: :chronometric_age,
#     attribute: %Attribute{
#       name: :verbatim_chronometric_age,
#       type: :string,
#       allow_nil?: true
#     }
#   }
# ]

# not used yet
# spp_attributes = [
#   %{
#     attribute: %Attribute{name: :species_profile_id, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :age_in_days, type: :integer, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :biotic_relationship, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :encoded_traits, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :host_disease_stat, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :is_hybrid, type: :boolean, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :life_form, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :mass_in_grams, type: :integer, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :pathogenicity, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :rel_to_oxygen, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :sex, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :size_in_millimeters, type: :integer, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :specific_host, type: :string, allow_nil?: true}
#   },
#   %{
#     attribute: %Attribute{name: :trophic_level, type: :string, allow_nil?: true}
#   }
# ]

categories = [
  %Category{
    name: :eve,
    label: "Event",
    description: "The circumstances of the extraction",
    attributes: Enum.map(eve_attributes, & &1.attribute),
    dwc_attributes: eve_attributes
  },
  %Category{
    name: :idf,
    label: "Identification",
    description: "Characteristics of the item",
    attributes: Enum.map(idf_attributes, & &1.attribute),
    dwc_attributes: idf_attributes
  },
  %Category{
    name: :tax,
    label: "Taxon",
    description: "Classification structure of the item",
    attributes: Enum.map(tax_attributes, & &1.attribute),
    dwc_attributes: tax_attributes
  },
  %Category{
    name: :loc,
    label: "Location",
    description: "Geographical description",
    attributes: Enum.map(loc_attributes, & &1.attribute),
    dwc_attributes: loc_attributes
  },
  %Category{
    name: :mte,
    label: "Material Entity",
    description: "Distinguishing marks of the specimen",
    attributes: Enum.map(mte_attributes, & &1.attribute),
    dwc_attributes: mte_attributes
  },
  %Category{
    name: :mts,
    label: "Material Sample",
    description: "Specimens documented (bio)chemical elements",
    attributes: Enum.map(mts_attributes, & &1.attribute),
    dwc_attributes: mts_attributes
  },
  %Category{
    name: :gec,
    label: "Geological Context",
    description: "Geological information, such as stratigraphy, that qualifies a region or a place",
    attributes: Enum.map(gec_attributes, & &1.attribute),
    dwc_attributes: gec_attributes
  },
  %Category{
    name: :org,
    label: "Organism",
    description: "A particular organism or defined group of organisms considered to be taxonomically homogeneous",
    attributes: Enum.map(org_attributes, & &1.attribute),
    dwc_attributes: org_attributes
  },
  %Category{
    name: :occ,
    label: "Occurrence",
    description: "An existence of a organism at a particular place at a particular time",
    attributes: Enum.map(occ_attributes, & &1.attribute),
    dwc_attributes: occ_attributes
  },
  %Category{
    name: :pvn,
    label: "Preservation",
    description:
      "Support for all kinds of preservations as an extension for Material Sample core sample data in Darwin Core. Intended to be a one to many relation to the Material Sample core",
    attributes: Enum.map(pvn_attributes, & &1.attribute),
    dwc_attributes: pvn_attributes
  },
  %Category{
    name: :oth,
    label: "Others",
    description: "Additional attributes which live outside of all other categories",
    attributes: Enum.map(oth_attributes, & &1.attribute),
    dwc_attributes: oth_attributes
  },
  %Category{
    name: :ext,
    label: "Extensions",
    description: "DWC Extension Data which belongs to the core data",
    attributes: Enum.map(ext_attributes, & &1.attribute),
    dwc_attributes: ext_attributes
  }
  # %Category{
  #   name: :spp,
  #   label: "Species Profile",
  #   description: "Life stage and characteristics of the species",
  #   attributes: Enum.map(spp_attributes, & &1.attribute),
  #   dwc_attributes: spp_attributes
  # },
  # %Category{
  #   name: :tas,
  #   label: "Types And Specimen",
  #   description:
  #     "An extension for specimens and types, including type specimens, type species and
  # type genera and simple specimens unrelated to types",
  #   attributes: Enum.map(tas_attributes, & &1.attribute),
  #   dwc_attributes: tas_attributes
  # },
  # %Category{
  #   name: :cma,
  #   label: "Chronometric Age",
  #   description:
  #     "Facilitate the sharing of information about chronometric ages and the techniques used to determine them",
  #   attributes: Enum.map(cma_attributes, & &1.attribute),
  #   dwc_attributes: cma_attributes
  # },
]

defmodule DataAggregator.DarwinCore.Schema do
  @moduledoc """
  Defines the Darwin Core schema and it's attributes.

  The schema is a map of categories, each category is a list of attributes. The attributes are defined as
  `Ash.Resource.Attribute` structs.

  ## Attributes by Category

  #{DataAggregator.DarwinCore.Schema.Docs.schema_docs(categories)}
  """

  alias Ash.Resource.Attribute
  alias DataAggregator.DarwinCore.Schema.Category

  @categories categories

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
  Returns a list of all mandatory (allow_nil == false) attribute names prefixed with their category name.
  """
  def mandatory_prefixed_attribute_names do
    Enum.map(mandatory_prefixed_attributes(), & &1.name)
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
  Returns a list of tuples containging the internal, prefixed attribute name and the dwc_field name
  """
  @spec prefixed_attribute_names_and_dwc_fields() :: [atom()]
  def prefixed_attribute_names_and_dwc_fields do
    Enum.flat_map(@categories, &Category.prefixed_attribute_names_and_dwc_fields/1)
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

  @doc """
  Returns the category of an attribute by the attributes name prefixed with the category name.
  """
  @spec category_from_prefixed_attribute_name(String.t()) :: Category.t() | nil
  def category_from_prefixed_attribute_name(name) when is_binary(name) do
    category_name = name |> String.split("_") |> List.first()

    Enum.find(@categories, &(&1.name == String.to_atom(category_name)))
  end

  @spec category_from_prefixed_attribute_name(atom()) :: Category.t() | nil
  def category_from_prefixed_attribute_name(name) when is_atom(name),
    do: category_from_prefixed_attribute_name(to_string(name))

  @doc """
  Returns the attribute name without the category prefix.
  """
  @spec attribute_name_without_prefix(String.t()) :: atom()
  def attribute_name_without_prefix(name) when is_binary(name) do
    name
    |> String.split("_")
    |> List.delete_at(0)
    |> Enum.join("_")
    |> String.to_atom()
  end

  @spec attribute_name_without_prefix(atom()) :: atom()
  def attribute_name_without_prefix(name) when is_atom(name), do: attribute_name_without_prefix(to_string(name))
end
