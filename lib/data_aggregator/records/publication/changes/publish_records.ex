defmodule DataAggregator.Records.Publication.Changes.PublishRecords do
  @moduledoc """
  Changeset hook to publication records
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &publish_records(&1, ctx), append?: true)
  end

  defp publish_records(%Changeset{data: original_publication} = changeset, %{actor: actor}) do
    publication = Ash.load!(original_publication, [:collection])

    case Collection.publish(publication, actor: actor, authorize?: false) do
      {:ok, publication} -> add_success(changeset, publication)
      {:error, error} -> add_error(changeset, error, publication)
    end
  end

  defp add_error(changeset, error, publication) do
    Logger.warning("Error while publishing records: #{inspect(error)}")
    Publication.set_failed(publication)
    Changeset.add_error(changeset, error)
  end

  defp add_success(changeset, publication) do
    publication = Publication.get_by_id!(publication.id)
    Logger.info("Successfully published #{publication.published_count} records")

    changeset
  end
end
