# Overview

Get insights to the project on a medium depht level. Understand concepts, without diving into the code.

## Brief summary

The Data Aggregator is a web application that is used to integrate biodiversity data into a Darwin Core compatible data format. The application is built using the Phoenix, and Ash Frameworks which are development utilities written in Elixir. The application is designed to be modular and extensible, allowing for the addition of new features and functionality as needed. It is a project of the Swiss Academy of Sciences (SCNAT) and is developed by Zebbra.

If there are - in your opinion - parts missing or if you detect issues, please create an issue on [Github]("https://github.com/zebbra/data_aggregator") or consider contribute by submitting a [PR]("https://github.com/zebbra/data_aggregator")

# The Application

We will describe the High- to Mid-Level concepts of the application. The goal is to give you a good understanding of the applications architecture and the main modules that cover the processes needed for import, enrichment, and publication of biodiversity data.

Throughout the documentation, we will use the `for_coders:` tag to indicate sections that are more technical in nature and contain hints to code sections where one can find corresponding elixir code modules. These sections are intended for developers and technical people who are interested in the inner workings of the application.

`for_coders:` checkout the [Development]("./development.md") section for more detailed information on how to work with the application as a developer and setup your local development environment. if you're a devops person, you might want to check out the [Deployment]("./deployment.md") section as well.

Consider as well play around with some tutorials or getting-started guides of the [Ash Framework]("https://ash-hq.org/") and the [Phoenix Framework]("https://www.phoenixframework.org/") which are the core of the application.

## Process

Among other sophisticated logic in the background, the core functionality is the pipeline of tranforming raw import data to a Darwin Core compatible format and publish it to GBIF. The process is divided into several steps, each of which is responsible for a specific task.

<img src="images/main_process.png" alt="Main process" width="100%">

`for_coders:` All the modules relevant to the backend functionality are located in the `lib/data_aggregator` directory. The `data_aggregator` module contains the core logic for the data aggregation process, while the `data_aggregator_api` module contains the API endpoints for the application. The `data_aggregator_web` module contains the web interface for the application.

---

### Upload

#### Validation

To ensure that the data is in the correct format and that it is complete, the application performs a series of validation checks on the data. If the data fails any of these checks, an error message is displayed to the user, and the data is not imported.

<img src="images/upload.png" alt="File Upload" width="50%">

Checks contain:

- File format: must be CSV, TSV, TXT, ARROW, IPC, PARQUET, PQT
- File size: must be less than 200MB
- Column headers must be present
- Line separators must be unix compatible (`\n`)
- Column separators must be compatible to the chosen file type (e.g. for `*.csv` or `*.tsv` it must be `,`, `;` or `\t`)
- The file must contain at least one row of data
- The file must contain at least two column of data
- The file must contain only valid UTF-8 characters

If one of those conditions do not match, the file will be rejected.

<img src="images/validation_error.png" alt="Validation" width="75%">

`for_coders:` All validation is done transaction save with [ash changes]("https://ash-hq.org/docs/guides/ash/latest/resources/changes"). So if one validation fails, the whole transaction will be rolled back and no records will be persisted. The same applies to the import process later on.

#### Mapping

The application allows the user to map the columns in the data file to the corresponding fields in the Darwin Core data model. This is done by selecting the appropriate field from a dropdown list for each column in the data file.

<img src="images/mapping.png" alt="Mapping" width="75%">

The mapping will then be used to transform the data into a Darwin Core compatible format. This means as well, that the chosen fields must be compatible with the Darwin Core fields. For example, if a selected column from my file contains integers, but the Darwin Core fild requires a `string` value, it will be rejected, and fails the import.

So please check if all the fields are correctly mapped, to avoid errors in the import process.

---

### Import

Importing the Data means, that the selected file will be stored on the S3, an import-object will be created in the database, and the data will be transformed into a Darwin Core compatible format according to the selected mapping in the previous step.

#### Store Data

The file will be stored on the S3, and the import object will be created in the database. The import object contains all the necessary information about the import, like the file name, the mapping, the amount of columns and rows, validation information and the status of the import.

`for_coders:` Handling files and storing them on the S3 is done by the `lib/data_aggregator/files` and `lib/data_aggregator/misc` modules

#### Report Errors

Should there be incompatibilities in the data, the application will report them on the import itself, so the user can correct them and re-import the data.

<img src="images/import_error.png" alt="Import Error" width="100%">

`for_coders:` The import process is handled by the `lib/data_aggregator/records/import` modules. This modules contain the logic for storing the file on the S3, creating the import object in the database, and transforming the data into a Darwin Core compatible format.

---

### Encoding

While for the user, the whole encoding process is abstracted and manageable over a single button on the collection in the UI, the application does a lot of work behind the curtain by checking if the raw data can be enriched with information stored in various catalogs/thesauri.

<img src="images/encode.png" alt="Encoding">

`for_coders:` The encoding process is handled by the `lib/data_aggregator/records/encoding` modules. This modules contain the logic for enriching the data with information from the catalogs/thesauri.

The overlaying `lib/data_aggregator/records/encoding/strategies/strategy.ex` module contains the logic for selecting the correct encoding strategy and provides some abstraction and common used helper functions for the encoding process.

Each encoding strategy is a module that implements the `encode/1` function, which takes the data and returns the enriched data.

Each encoding step produces a new version of the data, which is then passed to the next encoding step. This way, the data is enriched step by step until it is fully enriched.

Each encoding step produces ash resource objects of type `DataAggregator.Records.Encoding.RecordEncodingResult` which then will be stored in the database and can be used for further processing or as we do, for showing it to the user in the UI.

<img src="images/encoding_result.png" alt="Location Encoding">

#### Location

The Geo or Location Encoding is used to enrich the data with information about the location where the data was collected. This information is used to create a map of the data, which can be used to visualize the data in a more meaningful way on the Gbif portal.

We do reverse geo encoding, which means that we take the coordinates of the data and enrich it with information about the location.

And we do forward geo encoding, which means that we take the location information and enrich it with additional location information like municipality, canton, or country, but we do not use the provided coordinates, because this could lead to wrong information and is not reliable.

`for_coders:` The location encoding process is handled by the `lib/data_aggregator/records/encoding/strategies/location/reverse_geo_encoding_strategy.ex` and `forward_geo_encoding_strategy.ex` modules. This modules contains the logic for enriching the data with location information.

#### Gbif Taxonomy

The Gbif Taxonomy Encoding is used to enrich the data with information about the taxonomy tree of the record. It's important to have the correct taxonomy information, because this is used by Gbif and it's researchers to classify the data. It uses the gbif API to get the taxonomy information according to (at least) scientific name and kingdom.

`for_coders:` The Gbif Taxonomy Encoding process is handled by the `lib/data_aggregator/records/encoding/strategies/taxonomy/gbif_taxonomy_encoding_strategy.ex` module.

#### Swiss Taxonomy

To enrich the data with information about the Swiss taxonomy, we use the Swiss Taxonomic Backbone Catalog to get the taxonomy information according to the taxonID.

`for_coders:` Update the catalog, which is checked in to the git repository of this project under `priv/repo/swiss_taxonomic_backbone_catalog.csv`. create a PR with the updated catalog, if you want to add or change information in the catalog.

#### IUCN Redlist

To enrich the data with information about the IUCN Redlist which indicates how "endangered" a certain classified species is, we use the GBIF IUCN Redlist API Endpoint at `https://api.gbif.org/v1/species/2496198/iucnRedListCategory` to get the redlist information according to the taxonID of the species.

---

### Publication

Under the term "Publication" we understand the process of transforming the data into a Darwin Core Archive and publishing it to the GBIF Switzerland or "SVNHC" portal. It's done fully automatic and the user only has to click a single button in the UI to start the process --> "publish".

<img src="images/publish.png" alt="Publish">

The publication process starts and generates an publication object.

<img src="images/publication.png" alt="Publication">

`for_coders:` The publication process is handled by the `lib/data_aggregator/records/publication` modules. This modules contains the logic for transforming the data into a Darwin Core Archive and publishing it to the GBIF portal.

#### Create DWC-Archive

The Darwin Core Archive is a zip file that contains the data in a Darwin Core compatible format. The archive is created by the application and contains all the necessary information for the data to be published to the GBIF portal.

`for_coders:` The creation of the Darwin Core Archive is handled by the modules under `lib/data_aggregator/darwin_core/publication`.

#### Publish to SVNHC

The publication process is done by registering the previously created Darwin Core Archive with the Registration API `https://api.gbif-uat.org/v1/dataset` on Gbif and makes it then available to be crawled from Gbif for making it available to the public.

`for_coders:` The publication process is handled by the `DataAggregator.Records.Actions.Publish` Ash Action.

### Approve

To have the data published on the GBIF portal, it must be approved by the Infospecies Switzerland team. The team will review the data and approve it if it meets the necessary requirements.
To start the approval process, the user must click the `approve` button in the UI on the collection.

An API endpoint is available to import the approved data from Infospecies into the application. The data will be imported into the application and can records will be indicated as `approved`.

`for_coders:` The approval process is handled by the `DataAggregator.Records.Actions.Approve` Ash Action. There we collect the neccessary records according to the users selection, create Darwin Core Archives and notify the Infospecies team about the approval by mail.

Once the Infospecies team has approved the data, the data will be published to the GBIF portal AND the data aggregator can be called by Rest API `POST /api/json/approvals` containing the link to the DWC-Archive to inform us, that the data is approved and was published. The endpoint expects a JSON object in the following structure:

```json
{
  "data": {
    "attributes": {
      "file_url": "https://s3.cloud.zebbra.ch/data-aggregator-stag/files/fat_02wlChzH8FcfF3L9VIXXY1/AY_qEyOtfpS2yzRehd1Ddg.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=data-aggregator-stag%2F20240710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240710T141305Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=46e0768b97d5a72e5d4414e55fcc6aa0d7a3df5e1a6d261765a64bbc2e97cb44"
    }
  }
}
```

this will return a json object like bellow to the calling client to indicate that the approval was successfully created:

```json
{
  "data": {
    "attributes": {
      "state": "pending",
      "rows_count": 18,
      "inserted_at": "2024-07-10T14:32:47.282217Z",
      "updated_at": "2024-07-10T14:32:47.282217Z",
      "file_url": "https://s3.cloud.zebbra.ch/data-aggregator-stag/files/fat_02wlChzH8FcfF3L9VIXXY1/AY_qEyOtfpS2yzRehd1Ddg.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=data-aggregator-stag%2F20240710%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240710T141305Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=46e0768b97d5a72e5d4414e55fcc6aa0d7a3df5e1a6d261765a64bbc2e97cb44"
    },
    "id": "app_02x50wRhsNSm3e9aTd2p4B",
    "type": "approval"
  }
}
```

Now the client has to call the `PATCH /api/json/approvals/{id}/enqueue` endpoint to enqueue and start the approval process.

By calling `GET /api/json/approvals/{id}` the client can check the status of the approval process at any time.

All the code necessary to handle the approval process is located in the `lib/data_aggregator/records/approval` modules.
