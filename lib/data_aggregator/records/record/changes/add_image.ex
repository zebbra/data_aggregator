defmodule DataAggregator.Records.Record.Changes.AddImage do
  @moduledoc """
  Changeset hook to add an image to a record. This will manage relationship to Images.
  And start change on encoded record to update associated media.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.EncodedRecord

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_action(changeset, &add_image(&1, ctx))
  end

  defp add_image(%Changeset{arguments: %{image: image}, data: record} = changeset, %{actor: actor, tenant: tenant} = _ctx) do
    changeset = Changeset.manage_relationship(changeset, :images, [image], type: :append)

    record = Ash.load!(record, :encoded_record, tenant: tenant)
    EncodedRecord.add_image_url(record.encoded_record, image, actor: actor)

    changeset
  end
end
