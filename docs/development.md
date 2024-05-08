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

## Contribution

Contributors are welcome! Please ensure you provide a detailed description of your changes and/or expected behaviour and the reason behind it. If you are unsure, please open an issue first to discuss what you would like to change.
