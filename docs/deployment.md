# Deployment

## Tagging releases

We use the [git_ops](https://hexdocs.pm/git_ops/readme.html) package to manage our release. To tag a create a release tag, use the following command:

```bash
mix git_ops.release
git push --follow-tags
```

Now the CI/CD pipeline will be triggered and...

- Unit and integration tests will run
- A docker image will be created
- The docker image will be tagged with the git tag and other tags - semver, latest (if it is the main branch)
- The docker image will be pushed to the docker registry (quay.io/zebbra/data_aggregator)
- The new Release will be deployed to the staging environment automatically
- For Test and Production, the deployment has to be triggered manually by pulling the new docker image from quay.io and deploying it to system

## Roll out

No matter where and how you deploy, ensure you execute

```bash
bin/migrate
```

to have all migrations up, and

```bash
bin/catalog_init
```

to have the most recent static thesaurus data available. and

```bash
bin/users_init
```

to populate the database with some users. CAUTION: only use this on non production or development systems.

## Test - @infofauna

<em>tbd</em>

## Production - @infofauna

Ready to run in production? Please [check the deployment guides of the elixir phoenix community](https://hexdocs.pm/phoenix/deployment.html).

<em>tbd</em>

## Learn more about Elixir & Phoenix

-
- Official website Phoenix: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Forum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
