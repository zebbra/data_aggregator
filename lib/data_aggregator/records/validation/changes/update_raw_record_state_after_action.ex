defmodule DataAggregator.Records.Validation.Changes.UpdateRawRecordStateAfterAction do
  @moduledoc """
  Action call to `DataAggregator.Records.Validation.set_done/1` after the action
  """

  use Ash.Resource.Change

  import DataAggregator.Helpers, only: [maybe_performant_load_record: 2]

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.after_action(changeset, fn _, validated_record ->
      set_validated(validated_record, ctx)
    end)
  end

  defp set_validated(validated_record, %{actor: actor, tenant: tenant}) do
    validated_record = maybe_performant_load_record(validated_record, tenant)

    Record.update_validation_status!(validated_record.record, :validated,
      actor: actor,
      authorize?: false
    )

    {:ok, validated_record}
  end
end
