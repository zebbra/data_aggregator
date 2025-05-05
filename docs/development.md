# Development

Setup your machine to start contributing code

## Overview

- [Database](#database)
  - [Native installation](#native-installation)
  - [docker setup](#docker-setup)
- [OSX system dependencies](#install-osx-system-dependencies)
- [Project structure](#project-structure)
- [Start coding](#start-coding)
  - [Working with and modifying the database](#working-with-and-modifying-the-database)
  - [Table partitions](#table-partitions)
- [CI/CD](#cicd)
- [Editors](#editors)
  - [vscode](#vscode)
  - [zed](#zed)
- [Contribution](#contribution)

## Database

you need a running postgres 15 instance on your local machine

either use a native installation or a docker setup.

### Native installation

ensure you have a running instance on `port 5432` if you used brew to install postgres on your mac ensure your default user and password is set to `user: postgres, password: postgres`. if you can't login with this credentials execute the following command on your cli:
`/usr/local/opt/postgres@15/bin/createuser -s postgres -h localhost -p 5432` then login with `psql -h localhost -p 5432` and execute `\password postgres` to set the password of your `postgres`user

### docker setup

alternatively you can start a docker container doing all the magic for you.
a good starting point is to use the docker compose setup [`here`](https://github.com/felipewom/docker-compose-postgres/blob/main/docker-compose.yml)

## install OSX system dependencies

- install erlang `brew install erlang`
- install elixir `brew install elixir`

for windows or linux use your favourite package manager

## Project structure

The project is structured in a way that the code is separated into different folders. Each folder has a specific purpose and contains files that are related to that purpose. The following is a list of the folders and their purpose:

```bash
├── assets                  # Static assets such as images, stylesheets, and JavaScript files for the UI
│   ├── css
│   ├── js
│   └── vendor
├── config                  # Environment-specific configuration files
│   ├── config.exs          # Main config, if config will not be overridden by environment, this will be used
│   ├── dev.exs             # config only for development environment
│   ├── prod.exs            # config only for production environment
│   ├── runtime.exs         # config only for runtime environment, this should be used for prod runtime config
│   └── test.exs            # config only for test environment
├── lib
│   ├── data_aggregator     # Backend application code, each folder represents a dedicated module of the backend
│   ├── data_aggregator_api # Definitions of interfaces for the application
│   ├── data_aggregator_web # Frontend application code, the views and event handlers for the UI
├── priv
│   ├── cache               # Caches for various usecases within the application
│   ├── cldr                # Location specific formatting of units, data, and time
│   ├── gettext             # Translations for the application
│   ├── initialize          # Scripts to initialize the application, like seeding the thesaurus/catalogs
│   ├── repo                # Database relevant files, like migrations, seeds, and init scripts
│   └── static              # Static files that are served by the application to the client
├── storybook               # UI component library, to develop and test UI components in isolation on dev systems at http://localhost:4000/storybook/welcome
│   ├── blocks
│   ├── collections
│   ├── components
│   ├── examples
│   ├── layouts
│   └── styleguide
└── test                    # Unit and integration tests for the entire backend- and frontend-application
    ├── data_aggregator
    ├── data_aggregator_api
    ├── data_aggregator_web
```

## Start coding

- ensure you have your `.env` file in place in the root of the project folder (an example could be found in `.env.test`) and it get picket up by the application when you start it (e.g. use `direnv allow` to load the environment variables into your shell session or your favourite method to load env vars)
- Run `mix deps.get && mix compile --force && mix git_hooks.install` to work with the project specific git hooks
- Run `docker compose up` in one of your terminals, to start services around our application - if there are any
- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to see the app and start developing.

### Working with and modifying the database

hard init whole system including reset of all migrations (during development):

```bash
# delete snapshots
rm -rf priv/resource_snapshots/*

# delete all migrations
rm -rf priv/repo/migrations/*_*.exs

# drop database
mix repo.drop

# create database and run migrations
mix setup
```

gradualy apply changes to the database (regular development):

```bash
# generate migration with new database changes
mix ash_postgres.generate_migrations --name your_migration_name
```

please check the generated migration files under `priv/repo/migrations` into your git repository. if you made datatype changes or removals of attributes - or any possibly destructive changes - it might be commented out and has to be commented in before committing.

```bash
# run migrations
mix repo.migrate
```

after you have successfully applied the changes to the database, ensure committing the migration files to the git repository.

### Table partitions

Due to performance issues we introduced table partitions for all resources related to records. The partitions inherit their parent table schema and are splitted by collection_id. Following tables are partitioned:

- validated_records
- published_records
- encoded_records
- encoded_record_versions
- import_records
- record_encoding_results
- record_images
- records
- record_versions

For table partitioning to work we need to include the collection_id into the primary key constraint. However, for the following resources this is not possible due to the limitations of ash_paper_trail:

- encoded_records
- encoded_record_versions
- records
- record_versions

For those resources we created the composite primary key (collection_id, id) manually in the [migration file](../priv/repo/migrations/20241105144203_create_records_partitions.exs). This means, that the database schema is not in sync with the resource dsl / snapshot. Please account for this when working with those resources (eg. when creating new migrations).

## CI/CD

Continuous Integration and Continuous Deployment is setup with Github Actions. The configuration is located in `.github/workflows/` and is triggered on every `push` of a `branch` and `tag`.

## Editors

### vscode

The project is setup to work with vscode. Under `./vscode` you find the necessary settings to work with the project as well as extensions which has to be installed (should automatically be suggested by vscode during startup)

### zed

Use `mix format` (instead of Elixir LS) to format source code:

```json
{
  "language_overrides": {
    "Elixir": {
      "format_on_save": {
        "external": {
          "command": "mix",
          "arguments": ["format", "--stdin-filename", "{buffer_path}", "-"]
        }
      }
    }
  }
}
```

### mcp server

we expose a mcp server on port 4000 with [tidewave-ai](https://github.com/tidewave-ai/tidewave_phoenix?tab=readme-ov-file). There is a configuration for copilot under `./vscode` already in place. If you don't use copilot, set http://localhost:4000/tidewave/mcp as endpoint for your ai assistant of choice.

## Contribution

Contributors are welcome! Please ensure you provide a detailed description of your changes and/or expected behaviour and the reason behind it. If you are unsure, please open an issue first to discuss what you would like to change.
