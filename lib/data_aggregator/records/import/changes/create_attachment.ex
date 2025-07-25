defmodule DataAggregator.Records.Import.Changes.CreateAttachment do
  @moduledoc """
  `Ash.Resource.Change` to create an import attachment.
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)
    filename = Changeset.get_argument(changeset, :filename)

    attachment = %{path: path, filename: filename}

    Changeset.manage_relationship(changeset, :attachment, attachment, type: :create)
  end
end
