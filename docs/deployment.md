# Deployment

## Tagging releases

To tag a create a release tag, use the following command:

```bash
git tag -a v1.1.0 -m "Release 1.1.0 and other notes"
git push --tags
```

Now the CI/CD pipeline will be triggered and...

- Unit and integration tests will run
- A docker image will be created
- The docker image will be tagged with the git tag and other tags - semver, latest (if it is the main branch)
- The docker image will be pushed to the docker registry (quay.io/zebbra/data_aggregator)
- The new Release will be deployed to the staging environment automatically
- For Test and Production, the deployment has to be triggered manually by pulling the new docker image from quay.io and deploying it to system

## Staging - @zebbra

if you do this step the first time,

- deploy the helm under `/helm` with `helmfile apply helmfile.yaml` to be sure all artifacts are available on the kubernetes cluster.
- check with [Lens](https://k8slens.dev/) or [kubectl](https://kubernetes.io/docs/reference/kubectl/) if the pods are running and ready.
- if not, check the logs. it might be possible that you have to add the necessary environment variables (`config/.env.prod`) as config map (non sensitive data) or secret (sensitive data) to the kubernetes cluster.

all subsequent deployments will go automatically after pushing/merging branches to the `main` branch.
if you change environment variables, ensure you update the config map/secrets on the k8s cluster.

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
