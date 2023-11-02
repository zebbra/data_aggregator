# Development

Setup your machine to start contributing code

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

## Start coding

- Run `mix deps.get && mix compile --force && mix git_hooks.install` to work with the project specific git hooks
- Run `docker compose up` in one of your terminals, to start services around our application
- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser to see the app

on [`localhost:9000`](http://localhost:9000) minio, our S3 storage is running. you can check uploaded files there as well

### modifying the database

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
