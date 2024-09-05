```mermaid
classDiagram
    class Collection {
        UUID id
        Integer items_to_digitize
        String owner
        String name
        String code
        String grscicoll_reference
        String grscicoll_institution_key
        String grscicoll_institution_code
        String grscicoll_institution_name
        String description
        String gbif_dataset_key
        Map[] import_mapping
        CollectionType type
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID institution_id
        Atom state
        Float digitizing_progress
        Integer records_count
        Institution institution
        Import[] imports
        Export[] exports
        Record[] records
        update(Integer items_to_digitize, String owner, String name, String code, ...)
        read(String sort)
        create(Integer items_to_digitize, String owner, String name, String code, ...)
        update_import_mapping(Map[] import_mapping)
        touch(Integer items_to_digitize, String owner, String name, String code, ...)
        register_at_gbif(String dwca_file_url, Integer items_to_digitize, String owner, String name, ...)
        set_importing()
        set_exporting()
        set_encoding()
        set_fast_track_publishing()
        set_approving()
        set_deleting()
        set_idle()
        set_idle_encoding()
        destroy()
        export(Struct export)
        publish(Struct publication)
        approve(Struct collection, Map query)
    }
    class EncodedRecord {
        Map ext_vernacular_names
        Map ext_species_profile
        Map ext_species_distribution
        Map ext_references
        Map ext_resource_relationship
        Map ext_permit
        Map ext_chronometric
        Map ext_assertions
        Map ext_amplification
        String oth_specify_author_of_record
        String oth_specify_event
        String oth_specify_locality
        String oth_specify_organism_name
        String oth_specify_person
        String oth_type
        String oth_rights_holder
        String oth_owner_institution_code
        String oth_modified_by
        String oth_license
        String oth_language
        String oth_institution_id
        String oth_institution_code
        String oth_information_withheld
        String oth_date_available
        String oth_dataset_name
        String oth_dataset_id
        String oth_data_generalizations
        String oth_collection_id
        String oth_collection_code
        String oth_bibliographic_citation
        String oth_basis_of_record
        String oth_access_rights
        String pvn_tissue_bank_institution
        String pvn_storage_name
        String pvn_preservation_type
        String pvn_sequence
        String pvn_preservation_temperature
        String pvn_preservation_special_mode
        String pvn_preservation_quality
        String pvn_preservation_mode_text
        String pvn_preservation_mode_keywords
        String pvn_preservation_method
        String pvn_preservation_id
        String pvn_preservation_date_begin
        String pvn_preservation_alteration_text
        String pvn_dna_storage_code
        String pvn_dna_bank_institution
        String occ_occurrence_id
        String org_organism_remarks
        String org_organism_scope
        String org_organism_name
        String org_organism_id
        String org_pathway
        String org_degree_of_establishment
        String org_establishment_means
        String org_sex
        String gec_place_of_origin
        String gec_member
        String gec_group
        String gec_formation
        String gec_lithostratigraphic_terms
        String gec_highest_biostratigraphic_zone
        String gec_lowest_biostratigraphic_zone
        String gec_latest_age_or_highest_stage
        String gec_latest_epoch_or_highest_series
        String gec_latest_period_or_highest_system
        String gec_latest_era_or_highest_erathem
        String gec_latest_eon_or_highest_eonothem
        String gec_earliest_period_or_lowest_system
        String gec_earliest_era_or_lowest_erathem
        String gec_earliest_epoch_or_lowest_series
        String gec_earliest_eon_or_lowest_eonothem
        String gec_earliest_age_or_lowest_stage
        String gec_bed
        String gec_geological_context_id
        String mts_material_sample_type
        String mts_material_sample_id
        String mte_original_biominerals
        String mte_orig_col_author
        Integer mte_year_collection_entrance
        String mte_tissue_bank_id
        String mte_taphonomy
        String mte_sample_designation
        String mte_orientation
        String mte_organism_quantity_method
        String mte_mineralization
        String mte_matrix
        String mte_gbif_doi
        String mte_form
        String mte_feeding_predation_traces
        String mte_extraction_temporary_id
        String mte_encrustation
        String mte_dna_stable_id
        String mte_dna_bank_id
        String mte_depositional_environment_type
        String mte_depositional_environment_text
        String mte_completeness
        String mte_paleo_completeness
        String mte_catalog_number
        String mte_bioerosion
        String mte_assemblage_origin
        String mte_articulation
        String mte_permit_id
        String mte_replacement_minerals
        String mte_barcode_label
        String mte_references
        String mte_other_catalog_numbers
        String mte_associated_media
        String mte_occurrence_status
        String mte_behavior
        String mte_reproductive_condition
        String mte_life_stage
        String mte_organism_quantity_type
        String mte_organism_quantity
        String mte_recorded_by_id
        String mte_recorded_by
        String mte_record_number
        String mte_material_entity_remarks
        String mte_preparations
        String mte_verbatim_label
        String mte_post_burial_transportation
        String mte_part_of_organism
        String mte_parent_material_entity_id
        String mte_anatomical_description
        String mte_material_entity_id
        Float loc_swiss_coordinates_y
        Float loc_swiss_coordinates_x
        String loc_georeference_verification_status
        String loc_georeference_remarks
        String loc_georeference_sources
        String loc_georeference_protocol
        Date loc_georeferenced_date
        String loc_georeferenced_by
        Float loc_footprint_spatial_fit
        String loc_footprint_srs
        String loc_footprint_wkt
        String loc_verbatim_srs
        String loc_verbatim_coordinate_system
        String loc_verbatim_longitude
        String loc_verbatim_latitude
        String loc_verbatim_coordinates
        Float loc_point_radius_spatial_fit
        Float loc_coordinate_precision
        Integer loc_coordinate_uncertainty_in_meters
        String loc_geodetic_datum
        String loc_location_remarks
        String loc_location_according_to
        Integer loc_maximum_distance_above_surface_in_meters
        Integer loc_minimum_distance_above_surface_in_meters
        Integer loc_verbatim_depth
        Integer loc_maximum_depth_in_meters
        Integer loc_minimum_depth_in_meters
        String loc_vertical_datum
        String loc_verbatim_elevation
        Integer loc_maximum_elevation_in_meters
        Integer loc_minimum_elevation_in_meters
        String loc_country_code
        String loc_municipality
        String loc_county
        Float loc_decimal_latitude
        Float loc_decimal_longitude
        String loc_state_province
        String loc_verbatim_locality
        String loc_locality
        String loc_country
        String loc_island
        String loc_island_group
        String loc_continent
        String loc_higher_geography
        String loc_water_body_id
        String loc_water_body
        String loc_higher_geography_id
        String loc_location_id
        String tax_taxon_remarks
        String tax_nomenclatural_status
        String tax_taxonomic_status
        String tax_nomenclatural_code
        String tax_vernacular_name
        String tax_verbatim_taxon_rank
        String tax_taxon_rank
        String tax_accepted_name_usage_id
        String tax_accepted_name_usage
        Integer tax_taxon_id_ch
        String tax_cultivar_epithet
        String tax_specific_epithet
        String tax_infraspecific_epithet
        String tax_infrageneric_epithet
        String tax_scientific_name_authorship
        String tax_generic_name
        String tax_scientific_name
        String tax_sub_tribe
        String tax_tribe
        String tax_sub_genus
        String tax_genus
        String tax_subfamily
        String tax_family
        String tax_order
        String tax_class
        String tax_superfamily
        String tax_phylum
        String tax_kingdom
        String tax_taxon_concept_id
        String tax_higher_classification
        String tax_name_published_in_year
        String tax_name_published_in
        String tax_name_published_in_id
        String tax_name_according_to
        String tax_name_according_to_id
        String tax_original_name_usage
        String tax_original_name_usage_id
        String tax_parent_name_usage
        String tax_parent_name_usage_id
        String tax_scientific_name_id
        Integer tax_identifier
        Integer tax_taxon_id
        String idf_last_verified_by_id
        String idf_last_verified_by
        String idf_verbatim_identification
        String idf_previous_identifications
        String idf_identified_by_id
        String idf_identification_verification_status
        String idf_identification_remarks
        String idf_identification_reference
        String idf_identification_qualifier
        String idf_evidence_type
        String idf_type_status
        String idf_identified_by
        Date idf_date_identified
        Float eve_shrub_layer_height_in_meters
        String eve_start_day_of_year
        String eve_sampling_effort
        Integer eve_sample_size_unit
        Integer eve_sample_size_value
        String eve_sampling_protocol
        String eve_substratum_state
        String eve_substratum
        String eve_micro_structure
        String eve_landscape_structure
        String eve_influence
        String eve_habitat_ref
        String eve_habitat_inclusion
        String eve_habitat_contact
        String eve_habitat_code
        Integer eve_end_of_period_year
        Integer eve_end_of_period_month
        Integer eve_end_of_period_day
        Integer eve_tree_layer_height_in_meters
        String eve_syntaxon_name
        String eve_project
        Boolean eve_mosses_identified
        Boolean eve_lichens_identified
        Integer eve_inclination_in_degrees
        Integer eve_herb_layer_height_in_centimeters
        String eve_event_remarks
        String eve_field_notes
        String eve_habitat
        String eve_verbatim_event_date
        Integer eve_year
        Integer eve_month
        Integer eve_day
        Integer eve_end_day_of_year
        String eve_event_time
        Date eve_event_date
        String eve_field_number
        String eve_parent_event_id
        String eve_event_id
        Float eve_cover_water_in_percentage
        Float eve_cover_trees_in_percentage
        Float eve_cover_total_in_percentage
        Float eve_cover_shrubs_in_percentage
        Float eve_cover_rock_in_percentage
        Float eve_cover_mosses_in_percentage
        Float eve_cover_litter_in_percentage
        Float eve_cover_lychens_in_percentage
        Float eve_cover_herbs_in_percentage
        Float eve_cover_cryptogams_in_percentage
        Float eve_cover_algae_in_percentage
        String eve_aspect
        UUID id
        Map extra_data
        String iucn_redlist_category
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID record_id
        Record record
        SwissSpecies[] swiss_species
        destroy()
        update(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        read(String sort)
        create(Struct record, Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, ...)
    }
    class RecordEncodingResult {
        UUID id
        Map input
        Map output
        String message
        Catalog catalog
        EncodingResultState state
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID record_id
        Record record
        destroy()
        read()
        filter_by_record(String record_id)
        filter_by_collection(String collection_id)
        create(Struct record, Map input, Map output, String message, ...)
        update(Struct record, Map input, Map output, String message, ...)
    }
    class Export {
        UUID id
        String name
        UtcDatetime exported_at
        UtcDatetime started_at
        UtcDatetime finished_at
        Map mapping
        Map records_query
        Integer exported_count
        Integer rows_count
        HeaderSourceType header_source
        DataLayerType data_layer
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID collection_id
        UUID attachment_id
        Atom state
        Collection collection
        Attachment attachment
        destroy()
        read()
        by_collection(String collection_id, String sort)
        create(Struct collection, String name, UtcDatetime exported_at, UtcDatetime started_at, ...)
        update_mapping(Map mapping, String name, UtcDatetime exported_at, UtcDatetime started_at, ...)
        update(Struct[] records, String name, UtcDatetime exported_at, UtcDatetime started_at, ...)
        enqueue()
        add_export_progress(Integer exported)
        set_running()
        set_failed()
        run()
        set_exported()
        update_attachment(Struct attachment)
    }
    class Import {
        UUID id
        Column[] columns
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UtcDatetime started_at
        UtcDatetime finished_at
        Integer rows_count
        Integer rows_valid_count
        Integer rows_invalid_count
        Integer rows_imported_count
        Integer rows_error_count
        UUID collection_id
        UUID attachment_id
        UUID error_log_id
        Atom state
        Integer records_count
        Collection collection
        Attachment attachment
        Attachment error_log
        Record[] records
        update(Column[] columns, UtcDatetime started_at, UtcDatetime finished_at, Integer rows_count, ...)
        destroy()
        read(String sort)
        by_collection(String collection_id, String sort)
        create(Struct collection, Column[] columns, UtcDatetime started_at, UtcDatetime finished_at, ...)
        create_from_path(Struct collection, String path, String filename)
        update_mapping(Column[] columns)
        add_validation_progress(Integer valid, Integer invalid)
        enqueue_import()
        import()
        set_importing()
        add_import_progress(Integer imported)
        set_failed()
        set_imported()
        update_error_log(Struct error_log)
    }
    class Record {
        UUID import_id
        UUID record_id
        Import import
        Record record
        update(UUID import_id, UUID record_id)
        destroy()
        read()
        create(Struct import, Struct record, UUID import_id, UUID record_id)
    }
    class Publication {
        UUID id
        String name
        Atom channel
        UtcDatetime published_at
        UtcDatetime started_at
        UtcDatetime finished_at
        Map records_query
        Integer published_count
        Integer rows_count
        Atom center
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID collection_id
        UUID attachment_id
        Atom state
        Collection collection
        Attachment attachment
        update(String name, Atom channel, UtcDatetime published_at, UtcDatetime started_at, ...)
        destroy()
        read()
        by_collection(String collection_id, String sort)
        create(Struct collection, String name, Atom channel, UtcDatetime published_at, ...)
        enqueue()
        add_publication_progress(Integer published)
        set_running()
        set_failed(String name, Atom channel, UtcDatetime published_at, UtcDatetime started_at, ...)
        run()
        set_done()
        update_attachment(Struct attachment)
    }
    class Record {
        Map ext_vernacular_names
        Map ext_species_profile
        Map ext_species_distribution
        Map ext_references
        Map ext_resource_relationship
        Map ext_permit
        Map ext_chronometric
        Map ext_assertions
        Map ext_amplification
        String oth_specify_author_of_record
        String oth_specify_event
        String oth_specify_locality
        String oth_specify_organism_name
        String oth_specify_person
        String oth_type
        String oth_rights_holder
        String oth_owner_institution_code
        String oth_modified_by
        String oth_license
        String oth_language
        String oth_institution_id
        String oth_institution_code
        String oth_information_withheld
        String oth_date_available
        String oth_dataset_name
        String oth_dataset_id
        String oth_data_generalizations
        String oth_collection_id
        String oth_collection_code
        String oth_bibliographic_citation
        String oth_basis_of_record
        String oth_access_rights
        String pvn_tissue_bank_institution
        String pvn_storage_name
        String pvn_preservation_type
        String pvn_sequence
        String pvn_preservation_temperature
        String pvn_preservation_special_mode
        String pvn_preservation_quality
        String pvn_preservation_mode_text
        String pvn_preservation_mode_keywords
        String pvn_preservation_method
        String pvn_preservation_id
        String pvn_preservation_date_begin
        String pvn_preservation_alteration_text
        String pvn_dna_storage_code
        String pvn_dna_bank_institution
        String occ_occurrence_id
        String org_organism_remarks
        String org_organism_scope
        String org_organism_name
        String org_organism_id
        String org_pathway
        String org_degree_of_establishment
        String org_establishment_means
        String org_sex
        String gec_place_of_origin
        String gec_member
        String gec_group
        String gec_formation
        String gec_lithostratigraphic_terms
        String gec_highest_biostratigraphic_zone
        String gec_lowest_biostratigraphic_zone
        String gec_latest_age_or_highest_stage
        String gec_latest_epoch_or_highest_series
        String gec_latest_period_or_highest_system
        String gec_latest_era_or_highest_erathem
        String gec_latest_eon_or_highest_eonothem
        String gec_earliest_period_or_lowest_system
        String gec_earliest_era_or_lowest_erathem
        String gec_earliest_epoch_or_lowest_series
        String gec_earliest_eon_or_lowest_eonothem
        String gec_earliest_age_or_lowest_stage
        String gec_bed
        String gec_geological_context_id
        String mts_material_sample_type
        String mts_material_sample_id
        String mte_original_biominerals
        String mte_orig_col_author
        Integer mte_year_collection_entrance
        String mte_tissue_bank_id
        String mte_taphonomy
        String mte_sample_designation
        String mte_orientation
        String mte_organism_quantity_method
        String mte_mineralization
        String mte_matrix
        String mte_gbif_doi
        String mte_form
        String mte_feeding_predation_traces
        String mte_extraction_temporary_id
        String mte_encrustation
        String mte_dna_stable_id
        String mte_dna_bank_id
        String mte_depositional_environment_type
        String mte_depositional_environment_text
        String mte_completeness
        String mte_paleo_completeness
        String mte_catalog_number
        String mte_bioerosion
        String mte_assemblage_origin
        String mte_articulation
        String mte_permit_id
        String mte_replacement_minerals
        String mte_barcode_label
        String mte_references
        String mte_other_catalog_numbers
        String mte_associated_media
        String mte_occurrence_status
        String mte_behavior
        String mte_reproductive_condition
        String mte_life_stage
        String mte_organism_quantity_type
        String mte_organism_quantity
        String mte_recorded_by_id
        String mte_recorded_by
        String mte_record_number
        String mte_material_entity_remarks
        String mte_preparations
        String mte_verbatim_label
        String mte_post_burial_transportation
        String mte_part_of_organism
        String mte_parent_material_entity_id
        String mte_anatomical_description
        String mte_material_entity_id
        Float loc_swiss_coordinates_y
        Float loc_swiss_coordinates_x
        String loc_georeference_verification_status
        String loc_georeference_remarks
        String loc_georeference_sources
        String loc_georeference_protocol
        Date loc_georeferenced_date
        String loc_georeferenced_by
        Float loc_footprint_spatial_fit
        String loc_footprint_srs
        String loc_footprint_wkt
        String loc_verbatim_srs
        String loc_verbatim_coordinate_system
        String loc_verbatim_longitude
        String loc_verbatim_latitude
        String loc_verbatim_coordinates
        Float loc_point_radius_spatial_fit
        Float loc_coordinate_precision
        Integer loc_coordinate_uncertainty_in_meters
        String loc_geodetic_datum
        String loc_location_remarks
        String loc_location_according_to
        Integer loc_maximum_distance_above_surface_in_meters
        Integer loc_minimum_distance_above_surface_in_meters
        Integer loc_verbatim_depth
        Integer loc_maximum_depth_in_meters
        Integer loc_minimum_depth_in_meters
        String loc_vertical_datum
        String loc_verbatim_elevation
        Integer loc_maximum_elevation_in_meters
        Integer loc_minimum_elevation_in_meters
        String loc_country_code
        String loc_municipality
        String loc_county
        Float loc_decimal_latitude
        Float loc_decimal_longitude
        String loc_state_province
        String loc_verbatim_locality
        String loc_locality
        String loc_country
        String loc_island
        String loc_island_group
        String loc_continent
        String loc_higher_geography
        String loc_water_body_id
        String loc_water_body
        String loc_higher_geography_id
        String loc_location_id
        String tax_taxon_remarks
        String tax_nomenclatural_status
        String tax_taxonomic_status
        String tax_nomenclatural_code
        String tax_vernacular_name
        String tax_verbatim_taxon_rank
        String tax_taxon_rank
        String tax_accepted_name_usage_id
        String tax_accepted_name_usage
        Integer tax_taxon_id_ch
        String tax_cultivar_epithet
        String tax_specific_epithet
        String tax_infraspecific_epithet
        String tax_infrageneric_epithet
        String tax_scientific_name_authorship
        String tax_generic_name
        String tax_scientific_name
        String tax_sub_tribe
        String tax_tribe
        String tax_sub_genus
        String tax_genus
        String tax_subfamily
        String tax_family
        String tax_order
        String tax_class
        String tax_superfamily
        String tax_phylum
        String tax_kingdom
        String tax_taxon_concept_id
        String tax_higher_classification
        String tax_name_published_in_year
        String tax_name_published_in
        String tax_name_published_in_id
        String tax_name_according_to
        String tax_name_according_to_id
        String tax_original_name_usage
        String tax_original_name_usage_id
        String tax_parent_name_usage
        String tax_parent_name_usage_id
        String tax_scientific_name_id
        Integer tax_identifier
        Integer tax_taxon_id
        String idf_last_verified_by_id
        String idf_last_verified_by
        String idf_verbatim_identification
        String idf_previous_identifications
        String idf_identified_by_id
        String idf_identification_verification_status
        String idf_identification_remarks
        String idf_identification_reference
        String idf_identification_qualifier
        String idf_evidence_type
        String idf_type_status
        String idf_identified_by
        Date idf_date_identified
        Float eve_shrub_layer_height_in_meters
        String eve_start_day_of_year
        String eve_sampling_effort
        Integer eve_sample_size_unit
        Integer eve_sample_size_value
        String eve_sampling_protocol
        String eve_substratum_state
        String eve_substratum
        String eve_micro_structure
        String eve_landscape_structure
        String eve_influence
        String eve_habitat_ref
        String eve_habitat_inclusion
        String eve_habitat_contact
        String eve_habitat_code
        Integer eve_end_of_period_year
        Integer eve_end_of_period_month
        Integer eve_end_of_period_day
        Integer eve_tree_layer_height_in_meters
        String eve_syntaxon_name
        String eve_project
        Boolean eve_mosses_identified
        Boolean eve_lichens_identified
        Integer eve_inclination_in_degrees
        Integer eve_herb_layer_height_in_centimeters
        String eve_event_remarks
        String eve_field_notes
        String eve_habitat
        String eve_verbatim_event_date
        Integer eve_year
        Integer eve_month
        Integer eve_day
        Integer eve_end_day_of_year
        String eve_event_time
        Date eve_event_date
        String eve_field_number
        String eve_parent_event_id
        String eve_event_id
        Float eve_cover_water_in_percentage
        Float eve_cover_trees_in_percentage
        Float eve_cover_total_in_percentage
        Float eve_cover_shrubs_in_percentage
        Float eve_cover_rock_in_percentage
        Float eve_cover_mosses_in_percentage
        Float eve_cover_litter_in_percentage
        Float eve_cover_lychens_in_percentage
        Float eve_cover_herbs_in_percentage
        Float eve_cover_cryptogams_in_percentage
        Float eve_cover_algae_in_percentage
        String eve_aspect
        UUID id
        Map import_data
        Map extra_data
        Map errors
        PublicationStatusType fast_track_status
        ApprovalStatusType approval_status
        String iucn_redlist_category
        UtcDatetime last_approval_started_at
        UtcDatetime last_imported_at
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID collection_id
        Atom state
        Boolean full_text_search
        Float full_text_search_rank
        Tsquery tsquery
        Boolean iucn_redlist
        Integer mids_level
        Collection collection
        Import[] imports
        Image[] images
        Attachment[] image_attachments
        EncodedRecord encoded_record
        update(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        read(String sort)
        by_collection(String collection_id, String sort)
        create(Struct collection, Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, ...)
        import(Struct import, Map params, Map ext_vernacular_names, Map ext_species_profile, ...)
        enqueue_encoder()
        enqueue_fast_track_checker()
        bulk_import(Struct import, Term rows)
        encode(Term record, Atom catalog)
        check_if_fast_track_pubished(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        set_imported(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        set_encoding(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        set_encoded(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        set_encoding_failed(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        update_fast_track_status(Atom status, Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, ...)
        update_approval_status(Atom status, Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, ...)
        update_last_approval_started_at()
        destroy()
    }
    class Image {
        UUID id
        Integer size
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID attachment_id
        UUID record_id
        Attachment attachment
        Record record
        destroy()
        update(Integer size, UUID attachment_id, UUID record_id)
        read()
        create(Integer size, UUID attachment_id, UUID record_id)
    }
    class Version {
        UUID id
        Atom version_action_type
        Atom version_action_name
        String mte_catalog_number
        String tax_scientific_name
        UUID version_source_id
        Map changes
        Record version_source
        destroy()
        update(Atom version_action_type, Atom version_action_name, String mte_catalog_number, String tax_scientific_name, ...)
        read()
        create(Atom version_action_type, Atom version_action_name, String mte_catalog_number, String tax_scientific_name, ...)
    }
    class Version {
        UUID id
        Atom version_action_type
        Atom version_action_name
        UUID version_source_id
        Map changes
        EncodedRecord version_source
        destroy()
        update(Atom version_action_type, Atom version_action_name, UUID version_source_id, Map changes)
        read()
        create(Atom version_action_type, Atom version_action_name, UUID version_source_id, Map changes)
    }
    class Approval {
        UUID id
        String file_url
        Integer rows_count
        Integer rows_invalid_count
        Integer rows_approved_count
        Integer rows_error_count
        UtcDatetime started_at
        UtcDatetime finished_at
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID attachment_id
        UUID error_log_id
        Atom state
        Attachment attachment
        Attachment error_log
        update(String file_url, Integer rows_count, Integer rows_invalid_count, Integer rows_approved_count, ...)
        destroy()
        read()
        create(String file_url)
        enqueue()
        set_running()
        set_failed(String file_url, Integer rows_count, Integer rows_invalid_count, Integer rows_approved_count, ...)
        run()
        set_done()
        update_attachment(Struct attachment)
        add_validation_progress(Integer valid, Integer invalid)
        add_approval_progress(Integer approved, Integer invalid)
        update_error_log(Struct error_log)
    }
    class ApprovedRecord {
        Map ext_vernacular_names
        Map ext_species_profile
        Map ext_species_distribution
        Map ext_references
        Map ext_resource_relationship
        Map ext_permit
        Map ext_chronometric
        Map ext_assertions
        Map ext_amplification
        String oth_specify_author_of_record
        String oth_specify_event
        String oth_specify_locality
        String oth_specify_organism_name
        String oth_specify_person
        String oth_type
        String oth_rights_holder
        String oth_owner_institution_code
        String oth_modified_by
        String oth_license
        String oth_language
        String oth_institution_id
        String oth_institution_code
        String oth_information_withheld
        String oth_date_available
        String oth_dataset_name
        String oth_dataset_id
        String oth_data_generalizations
        String oth_collection_id
        String oth_collection_code
        String oth_bibliographic_citation
        String oth_basis_of_record
        String oth_access_rights
        String pvn_tissue_bank_institution
        String pvn_storage_name
        String pvn_preservation_type
        String pvn_sequence
        String pvn_preservation_temperature
        String pvn_preservation_special_mode
        String pvn_preservation_quality
        String pvn_preservation_mode_text
        String pvn_preservation_mode_keywords
        String pvn_preservation_method
        String pvn_preservation_id
        String pvn_preservation_date_begin
        String pvn_preservation_alteration_text
        String pvn_dna_storage_code
        String pvn_dna_bank_institution
        String occ_occurrence_id
        String org_organism_remarks
        String org_organism_scope
        String org_organism_name
        String org_organism_id
        String org_pathway
        String org_degree_of_establishment
        String org_establishment_means
        String org_sex
        String gec_place_of_origin
        String gec_member
        String gec_group
        String gec_formation
        String gec_lithostratigraphic_terms
        String gec_highest_biostratigraphic_zone
        String gec_lowest_biostratigraphic_zone
        String gec_latest_age_or_highest_stage
        String gec_latest_epoch_or_highest_series
        String gec_latest_period_or_highest_system
        String gec_latest_era_or_highest_erathem
        String gec_latest_eon_or_highest_eonothem
        String gec_earliest_period_or_lowest_system
        String gec_earliest_era_or_lowest_erathem
        String gec_earliest_epoch_or_lowest_series
        String gec_earliest_eon_or_lowest_eonothem
        String gec_earliest_age_or_lowest_stage
        String gec_bed
        String gec_geological_context_id
        String mts_material_sample_type
        String mts_material_sample_id
        String mte_original_biominerals
        String mte_orig_col_author
        Integer mte_year_collection_entrance
        String mte_tissue_bank_id
        String mte_taphonomy
        String mte_sample_designation
        String mte_orientation
        String mte_organism_quantity_method
        String mte_mineralization
        String mte_matrix
        String mte_gbif_doi
        String mte_form
        String mte_feeding_predation_traces
        String mte_extraction_temporary_id
        String mte_encrustation
        String mte_dna_stable_id
        String mte_dna_bank_id
        String mte_depositional_environment_type
        String mte_depositional_environment_text
        String mte_completeness
        String mte_paleo_completeness
        String mte_catalog_number
        String mte_bioerosion
        String mte_assemblage_origin
        String mte_articulation
        String mte_permit_id
        String mte_replacement_minerals
        String mte_barcode_label
        String mte_references
        String mte_other_catalog_numbers
        String mte_associated_media
        String mte_occurrence_status
        String mte_behavior
        String mte_reproductive_condition
        String mte_life_stage
        String mte_organism_quantity_type
        String mte_organism_quantity
        String mte_recorded_by_id
        String mte_recorded_by
        String mte_record_number
        String mte_material_entity_remarks
        String mte_preparations
        String mte_verbatim_label
        String mte_post_burial_transportation
        String mte_part_of_organism
        String mte_parent_material_entity_id
        String mte_anatomical_description
        String mte_material_entity_id
        Float loc_swiss_coordinates_y
        Float loc_swiss_coordinates_x
        String loc_georeference_verification_status
        String loc_georeference_remarks
        String loc_georeference_sources
        String loc_georeference_protocol
        Date loc_georeferenced_date
        String loc_georeferenced_by
        Float loc_footprint_spatial_fit
        String loc_footprint_srs
        String loc_footprint_wkt
        String loc_verbatim_srs
        String loc_verbatim_coordinate_system
        String loc_verbatim_longitude
        String loc_verbatim_latitude
        String loc_verbatim_coordinates
        Float loc_point_radius_spatial_fit
        Float loc_coordinate_precision
        Integer loc_coordinate_uncertainty_in_meters
        String loc_geodetic_datum
        String loc_location_remarks
        String loc_location_according_to
        Integer loc_maximum_distance_above_surface_in_meters
        Integer loc_minimum_distance_above_surface_in_meters
        Integer loc_verbatim_depth
        Integer loc_maximum_depth_in_meters
        Integer loc_minimum_depth_in_meters
        String loc_vertical_datum
        String loc_verbatim_elevation
        Integer loc_maximum_elevation_in_meters
        Integer loc_minimum_elevation_in_meters
        String loc_country_code
        String loc_municipality
        String loc_county
        Float loc_decimal_latitude
        Float loc_decimal_longitude
        String loc_state_province
        String loc_verbatim_locality
        String loc_locality
        String loc_country
        String loc_island
        String loc_island_group
        String loc_continent
        String loc_higher_geography
        String loc_water_body_id
        String loc_water_body
        String loc_higher_geography_id
        String loc_location_id
        String tax_taxon_remarks
        String tax_nomenclatural_status
        String tax_taxonomic_status
        String tax_nomenclatural_code
        String tax_vernacular_name
        String tax_verbatim_taxon_rank
        String tax_taxon_rank
        String tax_accepted_name_usage_id
        String tax_accepted_name_usage
        Integer tax_taxon_id_ch
        String tax_cultivar_epithet
        String tax_specific_epithet
        String tax_infraspecific_epithet
        String tax_infrageneric_epithet
        String tax_scientific_name_authorship
        String tax_generic_name
        String tax_scientific_name
        String tax_sub_tribe
        String tax_tribe
        String tax_sub_genus
        String tax_genus
        String tax_subfamily
        String tax_family
        String tax_order
        String tax_class
        String tax_superfamily
        String tax_phylum
        String tax_kingdom
        String tax_taxon_concept_id
        String tax_higher_classification
        String tax_name_published_in_year
        String tax_name_published_in
        String tax_name_published_in_id
        String tax_name_according_to
        String tax_name_according_to_id
        String tax_original_name_usage
        String tax_original_name_usage_id
        String tax_parent_name_usage
        String tax_parent_name_usage_id
        String tax_scientific_name_id
        Integer tax_identifier
        Integer tax_taxon_id
        String idf_last_verified_by_id
        String idf_last_verified_by
        String idf_verbatim_identification
        String idf_previous_identifications
        String idf_identified_by_id
        String idf_identification_verification_status
        String idf_identification_remarks
        String idf_identification_reference
        String idf_identification_qualifier
        String idf_evidence_type
        String idf_type_status
        String idf_identified_by
        Date idf_date_identified
        Float eve_shrub_layer_height_in_meters
        String eve_start_day_of_year
        String eve_sampling_effort
        Integer eve_sample_size_unit
        Integer eve_sample_size_value
        String eve_sampling_protocol
        String eve_substratum_state
        String eve_substratum
        String eve_micro_structure
        String eve_landscape_structure
        String eve_influence
        String eve_habitat_ref
        String eve_habitat_inclusion
        String eve_habitat_contact
        String eve_habitat_code
        Integer eve_end_of_period_year
        Integer eve_end_of_period_month
        Integer eve_end_of_period_day
        Integer eve_tree_layer_height_in_meters
        String eve_syntaxon_name
        String eve_project
        Boolean eve_mosses_identified
        Boolean eve_lichens_identified
        Integer eve_inclination_in_degrees
        Integer eve_herb_layer_height_in_centimeters
        String eve_event_remarks
        String eve_field_notes
        String eve_habitat
        String eve_verbatim_event_date
        Integer eve_year
        Integer eve_month
        Integer eve_day
        Integer eve_end_day_of_year
        String eve_event_time
        Date eve_event_date
        String eve_field_number
        String eve_parent_event_id
        String eve_event_id
        Float eve_cover_water_in_percentage
        Float eve_cover_trees_in_percentage
        Float eve_cover_total_in_percentage
        Float eve_cover_shrubs_in_percentage
        Float eve_cover_rock_in_percentage
        Float eve_cover_mosses_in_percentage
        Float eve_cover_litter_in_percentage
        Float eve_cover_lychens_in_percentage
        Float eve_cover_herbs_in_percentage
        Float eve_cover_cryptogams_in_percentage
        Float eve_cover_algae_in_percentage
        String eve_aspect
        UUID id
        Map extra_data
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        UUID record_id
        Record record
        destroy()
        update(Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, Map ext_references, ...)
        read(String sort)
        create(Struct record, Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, ...)
        approve(Struct record, Map ext_vernacular_names, Map ext_species_profile, Map ext_species_distribution, ...)
        bulk_approve(Term rows)
    }

    Attachment -- Approval
    Attachment -- Export
    Attachment -- Import
    Attachment -- Publication
    Attachment -- Record
    Attachment -- Image
    Institution -- Collection
    ApprovedRecord -- Record
    Collection -- Export
    Collection -- Import
    Collection -- Publication
    Collection -- Record
    EncodedRecord -- Version
    EncodedRecord -- Record
    EncodedRecord -- SwissSpecies
    RecordEncodingResult -- Record
    Import -- Record
    Import -- Record
    Record -- Record
    Record -- Image
    Record -- Version

```
