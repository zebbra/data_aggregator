# SVNHC-data-aggregator

Data Aggregator to integrate biodiversity data to a darwin core compatible data format

## Project

create an issue on [`jira`](https://infofauna-support.atlassian.net/jira/your-work)

checkout the documentation on [`confluence`](https://infofauna-support.atlassian.net/wiki/spaces/SCN/pages/3342625/Project+SwissCollNet+--+Implementation)

contribute by submitting a [`PR`](https://github.com/zebbra/data_aggregator)

checkout the [`data model`](https://dbdiagram.io/d/data-aggregator-generated-from-code-653795c6ffbf5169f0554c4f)

checkout our notes on [`miro`](https://miro.com/app/board/uXjVMBLi0fk=/)

## Development

setup your machine to start contributing code

### Database

you need a running postgres 15 instance on your local machine

either use a native installation or a docker setup.

#### native installation

ensure you have a running instance on `port 5432`
if you used brew to install postgres on your mac ensure your default user and password is set to `user: postgres, password: postgres`. if you can't login with this credentials execute the following command on your cli:
`/usr/local/opt/postgres@15/bin/createuser -s postgres -h localhost -p 5432` then login with `psql -h localhost -p 5432` and execute `\password postgres` to set the password of your `postgres`user

#### docker setup

alternatively you can start a docker container doing all the magic for you.
a good starting point is to use the docker compose setup [`here`](https://github.com/felipewom/docker-compose-postgres/blob/main/docker-compose.yml)

### install OSX system dependencies

- install erlang `brew install erlang`
- install elixir `brew install elixir`

for windows or linux use your favourite package manager

### Start coding

- Run `docker compose up` in one of your terminals, to start services around our application
- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to see the app

on [`localhost:9000`](http://localhost:9000) minio, our S3 storage is running. you can check uploaded files there as well

#### modifying the database

hard init whole system including reset of all migrations (during development):

```bash
# delete snapshots
rm -rf priv/resource_snapshots/*

# delete all migrations
rm -rf priv/repo/migrations/*_*.exs

# drop database
mix ash_postgres.drop

# generate migration to setup database
mix ash_postgres.generate_migrations --name initial_migration

# create database
mix ash_postgres.create

# run migrations
mix ash_postgres.migrate
```

gradualy apply changes to the database (regular development):

```bash
# generate migration with new database changes
mix ash_postgres.generate_migrations --name your_migration_name

# run migrations
mix ash_postgres.migrate
```

### api's

check and extend our [postman collection](https://martian-spaceship-337286.postman.co/workspace/Team-Workspace~5cea633a-4d4e-4e43-8460-39c3fc2774e7/collection/16163919-5357e4b8-3f23-4fb8-b105-139db31bfac5?action=share&creator=16163919&active-environment=16163919-86e22979-e529-484e-9372-a4f869876b27)

our [open-api schema](http://localhost:4000/api/json/open_api)

our [swagger-ui](http://localhost:4000/api/json/swagger)

our [redoc](http://localhost:4000/api/json/redoc)

## Staging

to deploy the application to our staging environment on the zebbra cloud

- deploy the helm under `/helm` with `helmfile apply helmfile.yaml`

or

- push your changes to the `main` branch and it will be deployed automatically

## Production

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Learn more

- Official website: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
