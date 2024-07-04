defmodule DataAggregator.Records.Record.Changes.CreateEncodedRecordAfterAction do
  @moduledoc """
  Calls `DataAggregator.Records.EncodedRecord.create/1` after the action has completed
  to create the associated `EncodedRecord`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.EncodedRecord

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &create_encoded_record/2)
  end

  defp create_encoded_record(_changeset, record) do
    Logger.debug("Create EncodedRecord ...")

    record
    |> Map.from_struct()
    |> Map.put_new_lazy(:record, fn -> record end)
    |> EncodedRecord.create!()

    {:ok, record}
  end
end
