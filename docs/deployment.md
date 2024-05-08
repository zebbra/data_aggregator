# Deployment

## Staging - @zebbra

to deploy the application to our staging environment on the zebbra cloud

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
