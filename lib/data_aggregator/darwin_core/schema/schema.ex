import DataAggregatorWeb.Helpers,
  only: [format_coordinate: 1, format_float: 1, format_json: 1]

alias Ash.Resource.Attribute
alias DataAggregator.DarwinCore.Schema.Category
alias DataAggregator.DarwinCore.Schema.CollectionAttribute

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
    attribute: %Attribute{name: :cover_total_in_percentage, type: :float, allow_nil?: true}
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
    attribute: %Attribute{name: :event_date, type: :string, allow_nil?: true}
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
      type: :float,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "inclinationInDegrees",
    dwc_link: "http://rs.gbif.org/terms/1.0/inclinationInDegrees",
    dwca_file: :releve,
    attribute: %Attribute{
      name: :inclination_in_degrees,
      type: :float,
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
      type: :float,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "endOfPeriodDay",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :end_of_period_day, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "endOfPeriodMonth",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :end_of_period_month, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "endOfPeriodYear",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :end_of_period_year, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "habitatCode",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :habitat_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "habitatContact",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :habitat_contact, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "habitatInclusion",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :habitat_inclusion, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "habitatRef",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :habitat_ref, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "influence",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :influence, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "landscapeStructure",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :landscape_structure, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "microStructure",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :micro_structure, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "substratum",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :substratum, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "substratumState",
    dwc_link: nil,
    dwca_file: nil,
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
    attribute: %Attribute{name: :sample_size_value, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "sampleSizeUnit",
    dwc_link: "http://rs.tdwg.org/dwc/terms/sampleSizeUnit",
    dwca_file: :core,
    attribute: %Attribute{name: :sample_size_unit, type: :string, allow_nil?: true}
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
  },
  %{
    dwc_field: "eventType",
    dwc_link: "http://rs.tdwg.org/dwc/terms/eventType",
    dwca_file: :core,
    attribute: %Attribute{name: :event_type, type: :string, allow_nil?: true}
  }
]

idf_attributes = [
  %{
    dwc_field: "dateIdentified",
    dwc_link: "http://rs.tdwg.org/dwc/terms/dateIdentified",
    dwca_file: :core,
    attribute: %Attribute{name: :date_identified, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identifiedBy",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identifiedBy",
    dwca_file: :core,
    attribute: %Attribute{name: :identified_by, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "typeStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/typeStatus",
    dwca_file: :core,
    attribute: %Attribute{name: :type_status, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "evidenceType",
    dwc_link: "http://rs.tdwg.org/dwc/terms/evidenceType",
    dwca_file: :core,
    attribute: %Attribute{name: :evidence_type, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationQualifier",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationQualifier",
    dwca_file: :core,
    attribute: %Attribute{name: :identification_qualifier, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationReferences",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationReferences",
    dwca_file: :core,
    attribute: %Attribute{name: :identification_reference, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :identification_remarks, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "identificationVerificationStatus",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationVerificationStatus",
    dwca_file: :core,
    attribute: %Attribute{
      name: :identification_verification_status,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "identifiedByID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identifiedByID",
    dwca_file: :core,
    attribute: %Attribute{
      name: :identified_by_id,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "previousIdentifications",
    dwc_link: "http://rs.tdwg.org/dwc/terms/previousIdentifications",
    dwca_file: :core,
    attribute: %Attribute{
      name: :previous_identifications,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "verbatimIdentification",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimIdentification",
    dwca_file: :core,
    attribute: %Attribute{
      name: :verbatim_identification,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "lastVerifiedBy",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{
      name: :last_verified_by,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "lastVerifiedByID",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{
      name: :last_verified_by_id,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "typifiedName",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{
      name: :typified_name,
      type: :string,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "identificationID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/identificationID",
    dwca_file: :core,
    attribute: %Attribute{name: :identification_id, type: :string, allow_nil?: true}
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
    dwc_field: "taxonIdCH",
    dwc_link: nil,
    dwca_file: nil,
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
    dwc_field: "waterBodyID",
    dwc_link: nil,
    dwca_file: nil,
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
    attribute: %Attribute{name: :minimum_elevation_in_meters, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "maximumElevationInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/maximumElevationInMeters",
    dwca_file: :core,
    attribute: %Attribute{name: :maximum_elevation_in_meters, type: :float, allow_nil?: true}
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
    attribute: %Attribute{name: :minimum_depth_in_meters, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "maximumDepthInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/maximumDepthInMeters",
    dwca_file: :core,
    attribute: %Attribute{name: :maximum_depth_in_meters, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "verbatimDepth",
    dwc_link: "http://rs.tdwg.org/dwc/terms/verbatimDepth",
    dwca_file: :core,
    attribute: %Attribute{name: :verbatim_depth, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "minimumDistanceAboveSurfaceInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/minimumDistanceAboveSurfaceInMeters",
    dwca_file: :core,
    attribute: %Attribute{
      name: :minimum_distance_above_surface_in_meters,
      type: :float,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "maximumDistanceAboveSurfaceInMeters",
    dwc_link: "http://rs.tdwg.org/dwc/terms/maximumDistanceAboveSurfaceInMeters",
    dwca_file: :core,
    attribute: %Attribute{
      name: :maximum_distance_above_surface_in_meters,
      type: :float,
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
      type: :float,
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
      type: :string,
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
    dwc_field: "swissCoordinatesLv03_E",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :swiss_coordinates_lv03_x, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "swissCoordinatesLv03_N",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :swiss_coordinates_lv03_y, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "swissCoordinatesLv95_E",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :swiss_coordinates_lv95_x, type: :float, allow_nil?: true}
  },
  %{
    dwc_field: "swissCoordinatesLv95_N",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :swiss_coordinates_lv95_y, type: :float, allow_nil?: true}
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
    dwc_link: nil,
    dwca_file: :resource_relationship,
    attribute: %Attribute{name: :parent_material_entity_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "partOfOrganism",
    dwc_link: nil,
    dwca_file: :resource_relationship,
    attribute: %Attribute{name: :part_of_organism, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "postBurialTransportation",
    dwc_link: nil,
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
    dwca_file: :core,
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
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :barcode_label, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "replacementMinerals",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :replacement_minerals, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "permitID",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :permit_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "articulation",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :articulation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "assemblageOrigin",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :assemblage_origin, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "bioerosion",
    dwc_link: nil,
    dwca_file: nil,
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
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :paleo_completeness, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "completeness",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :completeness, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "depositionalEnvironmentText",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :depositional_environment_text, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "depositionalEnvironmentType",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :depositional_environment_type, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dnaBankID",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :dna_bank_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dnaStableID",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :dna_stable_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "encrustation",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :encrustation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "extractionTemporaryID",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :extraction_temporary_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "feedingPredationTraces",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :feeding_predation_traces, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "form",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :form, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "matrix",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :matrix, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "mineralization",
    dwc_link: nil,
    dwca_file: nil,
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
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :orientation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "sampleDesignation",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :sample_designation, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "taphonomy",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :taphonomy, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "tissueBankID",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :tissue_bank_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "yearCollectionEntrance",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :year_collection_entrance, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "origColAuthor",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :orig_col_author, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "originalBiominerals",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :original_biominerals, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "disposition",
    dwc_link: "http://rs.tdwg.org/dwc/terms/disposition",
    dwca_file: :core,
    attribute: %Attribute{name: :disposition, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "associatedSequences",
    dwc_link: "http://rs.tdwg.org/dwc/terms/associatedSequences",
    dwca_file: :core,
    attribute: %Attribute{name: :associated_sequences, type: :string, allow_nil?: true}
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
    dwc_link: nil,
    dwca_file: nil,
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
  },
  %{
    dwc_field: "associatedOrganisms",
    dwc_link: "http://rs.tdwg.org/dwc/terms/associatedOrganisms",
    dwca_file: :core,
    attribute: %Attribute{name: :associated_organisms, type: :string, allow_nil?: true}
  }
]

occ_attributes = [
  %{
    dwc_field: "occurrenceID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/occurrenceID",
    dwca_file: :core,
    attribute: %Attribute{name: :occurrence_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "caste",
    dwc_link: "http://rs.tdwg.org/dwc/terms/caste",
    dwca_file: :core,
    attribute: %Attribute{name: :caste, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "individualCount",
    dwc_link: "http://rs.tdwg.org/dwc/terms/individualCount",
    dwca_file: :core,
    attribute: %Attribute{name: :individual_count, type: :integer, allow_nil?: true}
  },
  %{
    dwc_field: "associatedOccurrences",
    dwc_link: "http://rs.tdwg.org/dwc/terms/associatedOccurrences",
    dwca_file: :core,
    attribute: %Attribute{name: :associated_occurrences, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "associatedReferences",
    dwc_link: "http://rs.tdwg.org/dwc/terms/associatedReferences",
    dwca_file: :core,
    attribute: %Attribute{name: :associated_references, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "associatedTaxa",
    dwc_link: "http://rs.tdwg.org/dwc/terms/associatedTaxa",
    dwca_file: :core,
    attribute: %Attribute{name: :associated_taxa, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "occurrenceRemarks",
    dwc_link: "http://rs.tdwg.org/dwc/terms/occurrenceRemarks",
    dwca_file: :core,
    attribute: %Attribute{name: :occurrence_remarks, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "vitality",
    dwc_link: "http://rs.tdwg.org/dwc/terms/vitality",
    dwca_file: :core,
    attribute: %Attribute{name: :vitality, type: :string, allow_nil?: true}
  }
]

pvn_attributes = [
  %{
    dwc_field: "dnaBankInstitution",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :dna_bank_institution, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dnaStorageCode",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :dna_storage_code, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationAlterationText",
    dwc_link: nil,
    dwca_file: nil,
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
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationMethod",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_method, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationModeKeywords",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_mode_keywords, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationModeText",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_mode_text, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationQuality",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_quality, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationSpecialMode",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :preservation_special_mode, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "preservationTemperature",
    dwc_link: nil,
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
    dwc_link: nil,
    dwca_file: nil,
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
    dwc_link: nil,
    dwca_file: nil,
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
    dwc_field: "dataGeneralizations",
    dwc_link: "http://rs.tdwg.org/dwc/terms/dataGeneralizations",
    dwca_file: :core,
    attribute: %Attribute{name: :data_generalizations, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "datasetName",
    dwc_link: "http://rs.tdwg.org/dwc/terms/datasetName",
    dwca_file: :core,
    attribute: %Attribute{name: :dataset_name, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dateAvailable",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :date_available, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "gbifID",
    dwc_link: nil,
    dwca_file: :core,
    attribute: %Attribute{name: :gbif_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "gbifCHID",
    dwc_link: nil,
    dwca_file: :core,
    attribute: %Attribute{name: :gbif_ch_id, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "informationWithheld",
    dwc_link: "http://rs.tdwg.org/dwc/terms/informationWithheld",
    dwca_file: :core,
    attribute: %Attribute{name: :information_withheld, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "language",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :language, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "license",
    dwc_link: "http://rs.tdwg.org/dwc/terms/license",
    dwca_file: :core,
    attribute: %Attribute{name: :license, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "modifiedBy",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :modified_by, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "modified",
    dwc_link: nil,
    dwca_file: :modified,
    attribute: %Attribute{name: :modified, type: :string, allow_nil?: true}
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
    dwc_field: "specifyPerson",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :specify_person, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "specifyOrganismName",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :specify_organism_name, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "specifyLocality",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :specify_locality, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "specifyEvent",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :specify_event, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "specifyAuthorOfRecord",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :specify_author_of_record, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "swissSpeciesCenter",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :swiss_species_center, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "swissSpeciesRegistered",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :swiss_species_registered, type: :boolean, allow_nil?: true}
  },
  %{
    dwc_field: "swissSpeciesRegisteredAt",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{
      name: :swiss_species_registered_at,
      type: :utc_datetime,
      allow_nil?: true
    }
  },
  %{
    dwc_field: "measurementUnit",
    dwc_link: nil,
    dwca_file: :core,
    attribute: %Attribute{name: :measurement_unit, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "measurementValue",
    dwc_link: nil,
    dwca_file: :core,
    attribute: %Attribute{name: :measurement_value, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "typeDesignatedBy",
    dwc_link: nil,
    dwca_file: nil,
    attribute: %Attribute{name: :type_designated_by, type: :string, allow_nil?: true}
  },
  %{
    dwc_field: "dynamicProperties",
    dwc_link: nil,
    dwca_file: :core,
    attribute: %Attribute{name: :dynamic_properties, type: :map, allow_nil?: true}
  }
]

ext_attributes = [
  %{
    dwc_field: "amplification",
    dwc_link: nil,
    dwca_file: :amplification,
    attribute: %Attribute{name: :amplification, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "assertions",
    dwc_link: nil,
    dwca_file: :extended_measurement_or_facts,
    attribute: %Attribute{name: :assertions, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "chronometric",
    dwc_link: nil,
    dwca_file: :chronometric_age,
    attribute: %Attribute{name: :chronometric, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "permit",
    dwc_link: nil,
    dwca_file: :permit,
    attribute: %Attribute{name: :permit, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "resourceRelationship",
    dwc_link: nil,
    dwca_file: :resource_relationship,
    attribute: %Attribute{name: :resource_relationship, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "ext_references",
    dwc_link: nil,
    dwca_file: :references,
    attribute: %Attribute{name: :refs, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "speciesDistribution",
    dwc_link: nil,
    dwca_file: :distribution,
    attribute: %Attribute{name: :species_distribution, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "speciesProfile",
    dwc_link: nil,
    dwca_file: :species_profile,
    attribute: %Attribute{name: :species_profile, type: :map, allow_nil?: true}
  },
  %{
    dwc_field: "vernacularNames",
    dwc_link: nil,
    dwca_file: :vernacular_names,
    attribute: %Attribute{name: :vernacular_names, type: :map, allow_nil?: true}
  }
]

categories = [
  %Category{
    name: :eve,
    label: "Event",
    description: "An action that occurs at some location during some time.",
    dwc_attributes: eve_attributes
  },
  %Category{
    name: :idf,
    label: "Identification",
    description: "A taxonomic determination (e.g., the assignment to a dwc:Taxon).",
    dwc_attributes: idf_attributes
  },
  %Category{
    name: :tax,
    label: "Taxon",
    description:
      "A group of organisms (sensu http://purl.obolibrary.org/obo/OBI_0100026) considered by taxonomists to form a homogeneous unit.",
    dwc_attributes: tax_attributes
  },
  %Category{
    name: :loc,
    label: "Location",
    description: "A spatial region or named place.",
    dwc_attributes: loc_attributes
  },
  %Category{
    name: :mte,
    label: "Material Entity",
    description:
      "An entity that can be identified, exists for some period of time, and consists in whole or in part of physical matter while it exists.",
    dwc_attributes: mte_attributes
  },
  %Category{
    name: :mts,
    label: "Material Sample",
    description: "A material entity that represents an entity of interest in whole or in part.",
    dwc_attributes: mts_attributes
  },
  %Category{
    name: :gec,
    label: "Geological Context",
    description: "Geological information, such as stratigraphy, that qualifies a region or place.",
    dwc_attributes: gec_attributes
  },
  %Category{
    name: :org,
    label: "Organism",
    description: "A particular organism or defined group of organisms considered to be taxonomically homogeneous.",
    dwc_attributes: org_attributes
  },
  %Category{
    name: :occ,
    label: "Occurrence",
    description: "An existence of a dwc:Organism at a particular place at a particular time.",
    dwc_attributes: occ_attributes
  },
  %Category{
    name: :pvn,
    label: "Preservation",
    description:
      "Support for all kinds of preservations as an extension for Material Sample core sample data in Darwin Core. Intended to be a one to many relation to the Material Sample core",
    dwc_attributes: pvn_attributes
  },
  %Category{
    name: :oth,
    label: "Others",
    description: "Additional attributes which live outside of all other categories",
    dwc_attributes: oth_attributes
  },
  %Category{
    name: :ext,
    label: "Extensions",
    description: "DWC Extension Data which belongs to the core data",
    dwc_attributes: ext_attributes
  }
]

collection_attributes = [
  %CollectionAttribute{
    dwc_field: "collectionID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/collectionID",
    dwca_file: :core,
    name: :oth_collection_id,
    collection_field: :grscicoll_reference
  },
  %CollectionAttribute{
    dwc_field: "collectionCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/collectionCode",
    dwca_file: :core,
    name: :oth_collection_code,
    collection_field: :code
  },
  %CollectionAttribute{
    dwc_field: "datasetID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/datasetID",
    dwca_file: :core,
    name: :oth_dataset_id,
    collection_field: :gbif_dataset_key
  },
  %CollectionAttribute{
    dwc_field: "institutionCode",
    dwc_link: "http://rs.tdwg.org/dwc/terms/institutionCode",
    dwca_file: :core,
    name: :oth_institution_code,
    collection_field: :grscicoll_institution_code
  },
  %CollectionAttribute{
    dwc_field: "institutionID",
    dwc_link: "http://rs.tdwg.org/dwc/terms/institutionID",
    dwca_file: :core,
    name: :oth_institution_id,
    collection_field: :grscicoll_institution_key
  },
  %CollectionAttribute{
    dwc_field: "gbifDOI",
    dwc_link: nil,
    dwca_file: nil,
    name: :oth_gbif_doi,
    collection_field: :gbif_doi
  }
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
  alias DataAggregator.DarwinCore.Schema.CollectionAttribute
  alias DataAggregator.DarwinCore.Schema.DwcAttribute

  @categories categories
  @colleciton_attributes collection_attributes

  @doc """
  Returns a map attributes grouped by category.
  """
  @spec categories() :: [Category.t()]
  def categories, do: @categories

  @doc """
  Returns a list of all attributes that we take from the collection.
  """
  @spec collection_attributes() :: [CollectionAttribute.t()]
  def collection_attributes, do: @colleciton_attributes

  @doc """
  Returns the category label for a category description
  """
  @spec category_label_by_description(String.t()) :: String.t() | nil
  def category_label_by_description(description) do
    case Enum.find(@categories, fn category -> category.description == description end) do
      nil -> nil
      category -> category.label
    end
  end

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
  @spec mandatory_prefixed_attribute_names() :: [atom()]
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
  Returns a list of tuples containging the internal, prefixed attribute name and the dwc_field name including collection based attributes
  """
  @spec prefixed_attribute_names_and_dwc_fields_and_collection_fields() :: map()
  def prefixed_attribute_names_and_dwc_fields_and_collection_fields do
    %{
      record: Enum.flat_map(@categories, &Category.prefixed_attribute_names_and_dwc_fields/1),
      collection:
        Enum.map(@colleciton_attributes, fn attribute ->
          {attribute.collection_field, attribute.dwc_field}
        end)
    }
  end

  @doc """
  Returns the dwc_field name for a prefixed attribute name if found, otherwise
  it returns the attribute name.
  """
  @spec dwc_field_from_prefixed_attribute_name(atom()) :: atom()
  def dwc_field_from_prefixed_attribute_name(name) when is_binary(name) do
    dwc_field =
      List.keyfind(prefixed_attribute_names_and_dwc_fields(), String.to_atom(name), 0)

    if dwc_field do
      elem(dwc_field, 1)
    else
      name
    end
  end

  def dwc_field_from_prefixed_attribute_name(name) when is_atom(name) do
    dwc_field =
      List.keyfind(prefixed_attribute_names_and_dwc_fields(), name, 0)

    if dwc_field do
      elem(dwc_field, 1)
    else
      name
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
    |> String.to_existing_atom()
  end

  @spec attribute_name_without_prefix(atom()) :: atom()
  def attribute_name_without_prefix(name) when is_atom(name), do: attribute_name_without_prefix(to_string(name))

  @spec dwc_attributes_by_dwca_file_type(atom()) :: [DwcAttribute.t()]
  def dwc_attributes_by_dwca_file_type(dwca_file) do
    for_result =
      for category <- @categories do
        Enum.filter(category.dwc_attributes, fn dwc_attribute ->
          dwc_attribute.dwca_file == dwca_file
        end)
      end

    List.flatten(for_result)
  end

  @spec dwc_transformers() :: map()
  def dwc_transformers do
    %{
      loc_decimal_latitude: &format_coordinate/1,
      loc_decimal_longitude: &format_coordinate/1,
      loc_coordinate_uncertainty_in_meters: &format_float/1,
      loc_minimum_elevation_in_meters: &format_float/1,
      loc_minimum_depth_in_meters: &format_float/1,
      loc_maximum_depth_in_meters: &format_float/1,
      loc_minimum_distance_above_surface_in_meters: &format_float/1,
      loc_maximum_elevation_in_meters: &format_float/1,
      loc_verbatim_elevation: &format_float/1,
      loc_footprint_spatial_fit: &format_float/1,
      loc_point_radius_spatial_fit: &format_float/1,
      loc_coordinate_precision: &format_float/1,
      loc_maximum_distance_above_surface_in_meters: &format_float/1,
      ext_vernacular_names: &format_json/1,
      ext_species_profile: &format_json/1,
      ext_species_distribution: &format_json/1,
      ext_refs: &format_json/1,
      ext_resource_relationship: &format_json/1,
      ext_permit: &format_json/1,
      ext_chronometric: &format_json/1,
      ext_assertions: &format_json/1,
      ext_amplification: &format_json/1,
      eve_cover_water_in_percentage: &format_float/1,
      eve_cover_shrubs_in_percentage: &format_float/1,
      eve_cover_algae_in_percentage: &format_float/1,
      eve_cover_litter_in_percentage: &format_float/1,
      eve_cover_trees_in_percentage: &format_float/1,
      eve_cover_lychens_in_percentage: &format_float/1,
      eve_inclination_in_degrees: &format_float/1,
      eve_cover_cryptogams_in_percentage: &format_float/1,
      eve_cover_mosses_in_percentage: &format_float/1,
      eve_herb_layer_height_in_centimeters: &format_float/1,
      eve_shrub_layer_height_in_meters: &format_float/1,
      eve_cover_herbs_in_percentage: &format_float/1,
      eve_cover_rock_in_percentage: &format_float/1,
      eve_cover_total_in_percentage: &format_float/1,
      eve_tree_layer_height_in_meters: &format_float/1,
      oth_dynamic_properties: &format_json/1
    }
  end

  @doc """
  Checks if an attribute is a known attribute. Useful
  to determine if a mapped_to attribute is a custom attribute.
  """
  @spec known_attribute?(atom()) :: boolean()
  def known_attribute?(attr) when is_binary(attr) do
    attr |> String.to_existing_atom() |> known_attribute?()
  rescue
    _ -> false
  end

  def known_attribute?(attr) do
    Enum.member?(prefixed_attribute_names(), attr)
  end

  @spec attributes_of_type(atom()) :: [{atom(), atom()}]
  def attributes_of_type(type) do
    prefixed_attributes()
    |> Enum.filter(fn attribute -> attribute.type == type end)
    |> Enum.map(fn attribute -> {attribute.name, type} end)
  end
end
