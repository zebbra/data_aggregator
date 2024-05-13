defmodule DataAggregator.Records.Collection.Changes.RegisterAtGbif do
  @moduledoc """
  Registers a Collection via the gbif Rest API to make it available for publishing.

  according to the example provided by gbif https://github.com/gbif/registry/blob/master/registry-examples/src/test/scripts/register.sh
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  # TODO: TEST THIS!!!!!!!!!!!!
  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    dwca_file_url = Changeset.get_argument(changeset, :dwca_file_url)
    name = Changeset.get_attribute(changeset, :name)

    # TODO: get this from the grscicoll response during collection creation
    institution_key = Changeset.get_attribute(changeset, :grscicoll_institution_key)

    {:ok, dataset_key} =
      name |> registration_params(institution_key) |> register_collection(dwca_file_url)

    Changeset.change_attribute(changeset, :gbif_dataset_key, dataset_key)
  end

  defp register_collection(params, dwca_file_url) do
    # register collection at gbif --> https://api.gbif-uat.org/v1/dataset

    # TODO: check what happens if a collection is already registered...
    # TODO: mock this for tests

    case Req.post(
           url: System.get_env("GBIF_DATASET_URL"),
           auth: gbif_auth(),
           json: params
         ) do
      {:ok, response} ->
        if response.status == 201 do
          registration = response.body

          create_endpoint(dwca_file_url, registration)
        else
          {:error, "No valid response (status #{response.status}) from Gibif api"}
        end

      {:error, error} ->
        {:error, "Error during collection registering with params: #{inspect(params)}, #{inspect(error)}"}
    end
  end

  defp registration_params(name, institution_key) do
    %{
      title: name,
      type: "OCCURRENCE",
      installationKey: System.get_env("GBIF_INSTALLATION_KEY"),
      publishingOrganizationKey: institution_key,
      language: "eng"
    }
  end

  defp create_endpoint(dwca_file_url, registration) do
    params = %{
      "type" => "OCCURRENCE",
      "url" => dwca_file_url
    }

    case Req.post(
           url: ~c"#{System.get_env("GBIF_DATASET_URL")}/#{registration}/endpoint",
           auth: gbif_auth(),
           body: params
         ) do
      {:ok, response} ->
        if response.status == 201 do
          {:ok, response.body}
        else
          {:error, "No valid response (status #{response.status}) from Gibif api"}
        end

      {:error, error} ->
        {:error, "Error during endpoint creation with params: #{inspect(params)}, #{inspect(error)}"}
    end
  end

  defp gbif_auth, do: {:basic, "#{System.get_env("GBIF_USER")}:#{System.get_env("GBIF_PASSWORD")}"}
end
