# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [0.10.11](https://github.com/zebbra/data_aggregator/compare/v0.10.10...0.10.11) (2025-01-23)




### Features:

* publication-verifier: only do 3 attempts. Errors count as attempts. If still not published in last attempt, set record to publication_failed

* sidepanel: show collection based values in sidepanel.

* publication: add gbif_doi to collection when registering at gbif.

* encoding: remove add institution code encoding step

* dwca-file: take some data from the collection instead of the record in csv creation

* publication: change order of publish, to set dataset id before dwc file creation

* add unique identifiers to record resources. use gbifid instead of occurence id to store gbifid returned from fast track checker

* changelog: reflect published status change in changelog with actor

* published_records: do publication rules on appending records to published records

* published_records: added table partitions

* publication: change default of license of publication to cc by

* publication: first implementation of publication table appending

* publication-modal: correctly show info pretaining rules/checks

* geo-reverse-encoding: dont overwrite data on conversion. Round results to 10cm precision

* publication: implement publication rule

* publication: first implementation of publication check.

* publication: add funcitonality of choosing existing dataset keys on publication

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* because on r2 image paths are urls with multiple params we have to get only the path to determine the content-type

* Merge branch 'fix/prevent_browser_from_downloading_images_linked_on_gbif' of https://github.com/zebbra/data_aggregator into fix/prevent_browser_from_downloading_images_linked_on_gbif

* guess content type according to file extension

* prevent storage service from setting wrong response content type header

* set fallback content type for file serving

* set content-distribution header

* Merge remote-tracking branch 'origin/main' into fix/prevent_browser_from_downloading_images_linked_on_gbif

* proxy image requests: proxy images on the server side instead of making a http redirect to the file

* fixing wrong arrity function call

* explicit set content type to image to prevent the browser from start downloading the image instead of showing it

* remove run tag from test

* tackling division by zero error on calculation of import and validation progress; adding progress calculations to tests; adapted same logic and test to export logic; at prublication progress calculation similar checks already apply, tests extended

* added format_float with default precision of 10 decimal digits; added transformer and calling format_float for each field mentioned in SCN-418; extended test data; extended publication tests; added doctests

* deps: update formatters

* publication: only use new publication rule on fast_track channel

* migrations: delete unused migration

* migrations: remove faulty migrations

* publication_modal: change help text

* publish: improve modal workflow

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.10](https://github.com/zebbra/data_aggregator/compare/v0.10.9...0.10.10) (2025-01-22)




### Features:

* changelog: reflect published status change in changelog with actor

* published_records: do publication rules on appending records to published records

* published_records: added table partitions

* publication: change default of license of publication to cc by

* publication: first implementation of publication table appending

* publication-modal: correctly show info pretaining rules/checks

* geo-reverse-encoding: dont overwrite data on conversion. Round results to 10cm precision

* publication: implement publication rule

* publication: first implementation of publication check.

* publication: add funcitonality of choosing existing dataset keys on publication

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* because on r2 image paths are urls with multiple params we have to get only the path to determine the content-type

* Merge branch 'fix/prevent_browser_from_downloading_images_linked_on_gbif' of https://github.com/zebbra/data_aggregator into fix/prevent_browser_from_downloading_images_linked_on_gbif

* guess content type according to file extension

* prevent storage service from setting wrong response content type header

* set fallback content type for file serving

* set content-distribution header

* Merge remote-tracking branch 'origin/main' into fix/prevent_browser_from_downloading_images_linked_on_gbif

* proxy image requests: proxy images on the server side instead of making a http redirect to the file

* fixing wrong arrity function call

* explicit set content type to image to prevent the browser from start downloading the image instead of showing it

* remove run tag from test

* tackling division by zero error on calculation of import and validation progress; adding progress calculations to tests; adapted same logic and test to export logic; at prublication progress calculation similar checks already apply, tests extended

* added format_float with default precision of 10 decimal digits; added transformer and calling format_float for each field mentioned in SCN-418; extended test data; extended publication tests; added doctests

* deps: update formatters

* publication: only use new publication rule on fast_track channel

* migrations: delete unused migration

* migrations: remove faulty migrations

* publication_modal: change help text

* publish: improve modal workflow

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.9](https://github.com/zebbra/data_aggregator/compare/v0.10.8...0.10.9) (2025-01-16)




### Features:

* published_records: do publication rules on appending records to published records

* published_records: added table partitions

* publication: first implementation of publication table appending

* publication-modal: correctly show info pretaining rules/checks

* geo-reverse-encoding: dont overwrite data on conversion. Round results to 10cm precision

* publication: implement publication rule

* publication: first implementation of publication check.

* publication: add funcitonality of choosing existing dataset keys on publication

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* deps: update formatters

* publication: only use new publication rule on fast_track channel

* migrations: delete unused migration

* migrations: remove faulty migrations

* publication_modal: change help text

* publish: improve modal workflow

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.8](https://github.com/zebbra/data_aggregator/compare/v0.10.7...0.10.8) (2025-01-07)




### Features:

* publication-modal: correctly show info pretaining rules/checks

* geo-reverse-encoding: dont overwrite data on conversion. Round results to 10cm precision

* publication: implement publication rule

* publication: first implementation of publication check.

* publication: add funcitonality of choosing existing dataset keys on publication

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* deps: update formatters

* publication: only use new publication rule on fast_track channel

* migrations: delete unused migration

* migrations: remove faulty migrations

* publication_modal: change help text

* publish: improve modal workflow

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.7](https://github.com/zebbra/data_aggregator/compare/v0.10.6...0.10.7) (2024-12-11)




### Features:

* publication: add funcitonality of choosing existing dataset keys on publication

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* migrations: delete unused migration

* migrations: remove faulty migrations

* publication_modal: change help text

* publish: improve modal workflow

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.6](https://github.com/zebbra/data_aggregator/compare/v0.10.5...0.10.6) (2024-12-09)




### Features:

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* publish: improve modal workflow

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.5](https://github.com/zebbra/data_aggregator/compare/v0.10.4...0.10.5) (2024-12-06)




### Features:

* publication: use updated texts for modal

* publication: finish basic publication modal (override existing or create new dataset). Using an existing is blocked for now

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.4](https://github.com/zebbra/data_aggregator/compare/v0.10.3...0.10.4) (2024-12-05)




### Features:

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* live_view: push_navigate change for release 1.0

* ext: sidepanel display and export

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.3](https://github.com/zebbra/data_aggregator/compare/v0.10.2...0.10.3) (2024-12-03)




### Features:

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.2](https://github.com/zebbra/data_aggregator/compare/v0.10.1...0.10.2) (2024-11-28)




### Features:

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.1](https://github.com/zebbra/data_aggregator/compare/v0.10.0...0.10.1) (2024-11-28)




### Features:

* publication: change metadata in eml file creation and tests

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.10.0](https://github.com/zebbra/data_aggregator/compare/v0.9.5...0.10.0) (2024-11-27)




### Features:

* floating_tooltip: implemented with portal to and floating_ui

* bulk_versions: use for import create records versions

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* image_upload_dialog: change dialog close refernce to image_upload_modal

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.9.5](https://github.com/zebbra/data_aggregator/compare/v0.9.4...0.9.5) (2024-11-21)




### Features:

* publications: first work on performance improvements

* images: add calculation for proxy image url

* image-uplad: add incomplete status when there are unmapped images

* image-upload: fix relate image upload encoding strategy. Add tests

* oth_modified: added new dwc field

* changes: display only changed values during encoding

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* image-upload: save proxy image address to associatedMedia. Handle proxy to return attachment url

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* geo-encoding: use lv03 and lv95 swiss coords. Add logic to geo-reverse encoding.

* geo_encoding: upcase country code on forward/reverse geo encoding

* change some attributes from integer/text to float

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* combobox: wait for transitions to finish before portaling

* tom-select: use new paths to require modules

* image-mapping: fix image mapping logic for files that contain periods

* image-upload: add edge case handling

* refactor and test counter

* throttle export progress updates

* http cache typo

* remove cache path compile env dependency

* small fixes

* sidepanel: display all imported and only changed encoded values

* changes: handle reduce of empty list

* jobs: increase pruner limit to 10_000

* image-upload: handle hidden folders

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.9.4](https://github.com/zebbra/data_aggregator/compare/v0.9.3...0.9.4) (2024-11-08)




### Features:

* redirects: change for collection/publication/approval create actions

* user: validate and fix email on first modal step

* helm: use CloudNativePG cluster

* started_by: added relationships

* table_partition: performance tweaks

* table_partition: create partitions

* table_partition: add multi-tenancy to records and records_versions

* table_partition: add multi-tenancy to record_images

* table_partition: add multi-tenancy to record_encoding_results

* table_partition: add multi-tenancy to publications

* table_partition: add multi-tenancy to imports

* table_partition: add multi-tenancy to import_records

* table_partition: add multi-tenancy to image_uploads

* table_partition: add multi-tenancy to exports

* table_partition: add multi-tenancy to encoded_records and it's versions

* table_partition: add multi-tenancy to approvals and approved_records

* table_partition: prepare records by adding a unique index on id,collection_id

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* jobs: increase pruner limit to 10_000

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.9.3](https://github.com/zebbra/data_aggregator/compare/v0.9.2...0.9.3) (2024-10-30)




### Features:

* images: add relate_images encoding strategy

* image-upload: integrate into cancel action logic

* image-upload: support hidden files and single subdiredctories

* image-upload: small ui changes.

* image-upload: set collection busy when mapping images

* image-upload: add activity feed for add_image_url change

* image-upload: conditional edit text/icons depending on first run or rerun

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

* image-upload: add info text to mapping modal.

* image-upload: rename and recolor image upload state

* image-upload: Add log download button to summary

* image-upload: validate and delete files when extracting.

* image-upload: add file mapping and tests.

* image-upload: add file extraction after zip upload

* image-upload: First steps implementing image upload

### Bug Fixes:

* linting error

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.9.2](https://github.com/zebbra/data_aggregator/compare/v0.9.1...0.9.2) (2024-10-24)




### Features:

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

### Performance Improvements:

* records table: use generated db columns and assign_async operations

## [0.9.1](https://github.com/zebbra/data_aggregator/compare/v0.9.0...0.9.1) (2024-10-18)




### Features:

* kill-switch: implemented logic to abort import,export,encode,publish,approve actions

## [0.9.0](https://github.com/zebbra/data_aggregator/compare/v0.8.3...0.9.0) (2024-10-16)




## [v0.8.3](https://github.com/zebbra/data_aggregator/compare/v0.8.3...v0.8.3) (2024-10-16)




### Features:

* encoding: refresh stats only once after encoding finished

* add subscription topic record:update. small fixes

* sidepanel: refine sidepanel content

* geo-forwarding: only use state and country for forwarding. dont update municipality

* small changes/fixes for go live

* Add timeout env for export, import and change default timeout of export to 6 hours

* nav: add target _blank to tutorial and guide link

* publish: change to SwissNatColl publisher

* i18n: disable language switch

* audits: add actor to versions

* administration: Clarify deletion alert.

* encoding: Add institution key and id in a new encoding step

* records_count: store on collection and update when necessary

* coordinates: transform to nice representation

* get collection adn institution data from prod grscicoll

* action-modals: complete rework and minor bug fixes

* publish: Delete existing endpoints of dataset from gbif when publishing to gbif

* import: increase transaction timeout to 12 hours

* collection: Add institution info to collection table

* dwc-attributes: Show dwc attribute with camelcase

* auth: further work on policies

* users_init: add institutions to user_import

* auth: add subscriptions and improve sign out ui

* user: minor changes to user form

* encoding: set state to failed if one strategy fails

* collection: added deleting state to disable all interactions during deleting process

* gettext: changes according to upgrade guide

* encoding: use oban job to poll collection state and add lifeline plugin to recover stale executing jobs

* ash-v3: initial migration

* oban: set interval to 1min

* oban: set interval to 1min

* ash_pagify: move to external library

* full-text-search: update docs

* full-text-search: use generated tsvector data for records and encoded_records

* full-text-search: added Pagify.Tsearch module to handle dynamic tsvector

* pagify: minor refactoring

* full-text-search: basic search form done

* full-text-search: pagify done

* pagify: backport Ash3.0 upgrades which are already valid for Ash2.0

* error_handling: added 404 and 500 templates and ignore not_found and status < 500 sentry errors

* collection: added state_machine for actions

* filter_component: better filters

* filter_forms: implemented and included into pagify

* records: implement layer selection

* pagify: added scopes feature

* pagify: remove current_order_by as it is not used

* records: show / hide columns based on collection type

* import: order columns according to file header

* pagify: reworked actions

* pagify: added limit select to pagination and consolidated links

* pagify: added table

* pagify: added lots of tests and some bug fixes

* pagify: allow to pass action to pagify with arguments

* pagify: take current_order_by from pagify to skip default sorts from Ash.Resource

* pagify: more strict existing atom checks

* pagify: basic pagination done

* pagify: pass resource to meta and add get_option method

* replace_invalid_params: make replace_invalid_params? default to false

* ui: align_actions in page header

* combobox: implemented with tom-select.js

* encoding: add run and encode buttons

* pagination: show no results in case of no results

* components: extracted in separate modules

* responsive: added viewport-width logic

* nested_dialogs: done

* selection: added row selection with preview

* pagination: implemented basic version

* table: added cell align

* live_view: pass serialized_params to different actions

* cicd: remove manual mix migrate job

* phoenix1.7.9: apply all changes according to https://www.phoenixdiff.org/compare/1.7.7...1.7.9

* show: use slideover

* ui: table with sort

* headless: replace alpinejs

* bin/tests: use lint instead of format (for credo)

* ui: basics (color-mode, i18n) done

### Bug Fixes:

* custom-commands: start minimal app for custom init commands

* don't create LEAKPROOF functions

* users: Dont show admin toggle for non-admins

* collections: correctly show import button on empty collection based on role

* schema: Add dwc file name too extensions

* collection: do not allow duplicated grscicoll_reference

* schema: consolidate verbatim and date type formats

* tests: stub all http requests

* actor: use custom user_id attribute

* actor_migrations: after update ash_paper_trail

* storybook: add index to activity

* routing: navigate to collections from dashboard

* publish: now correctly sets record fast_track_status to failed when failing registering.

* publication: dont rollback state changes on failing publication

* import: disable type inference

* user_table: make sortable fields public

* tests: Add base url to envon test environment

* collections: show table headers for collection_type geology and paleontology

* increase DB migration job timeout

* encoded_record: remove foreign key constraint towards has_many swiss_species

* db: remove reference to swiss_species (code only)

* db: make version references deferrable

* db: create missing indexes

* db: remove unused tables/columns

* db: reference source record in versions

* db: add PK to encoded_records

* auth: fix show password toggle

* collection: allow admin to create any institution

* schema: fallback to prefixed attribute name if dwc_field is not available

* auth: apply ash_authentication_phoenix router changes

* migrate: undo Repo load

* login: hide dark image

* release: load some more repos

* tests: do not require authorization during business logic

* increase DB pool size

* revert set_imported action changes

* use branch from ash fork

* optimize import performance

* users_init: add missing scripts

* auth: use default logo as banner logo

* jobs: undo concurrency changes and set bulk_import timeout to 5 minutes

* jobs: disable some transactions

* jobs: reduce parallelity

* jobs: max concurrency 12

* encoding: do not overwrite encoding from previous strategy

* encoding: do not abort if a strategy fails

* upload: disable submit during upload (closes #387)

* tests: use authenticated sessions for live tests

* alert: closes #385

* error-logs: properly extract error message

* jobs: remove references

* import: detect duplicates and report in log-file

* migration: change names

* graphql: remove due to incompatibility

* record: correct iucn_redlist calculation

* config: set queue to 1

* layer: handle incorrect layer selection

* flash: and modal inoperability

* gbif_url: move to config

* flash: reset timeout on update

* export: only export filtered records

* filter_component: change filters

* format_date: properly handle nil case

* records: display stats and toolbar in case total_counts is 0

* pagify: docs close backquotes

* pagify: order asc_nils_last -> asc_nils_first

* secondary_navigation: move to index page

* after_actions: remove invalid append: true setting

* mapping: store mapping on collection only after save

* mapping: correct reuse_mapping logic

* helm: define http_cache_path in prod.exs to overcome compile<->runtime issues

* helm: use catalog-init as name to conform RFC

* import.mappings: load relation in imports/show

* ios: css and scroll-lock

* table: use results as namespace and handle sort in collections

* upload: styling and ensure dir exists

* flash: default id fun

* runtime: assign environment in global live state

* runtime: use correct bandit http options #2

* runtime: use correct bandit http options

* Dockerfile: install npm
