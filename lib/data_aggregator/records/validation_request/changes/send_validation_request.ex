defmodule DataAggregator.Records.ValidationRequest.Changes.SendValidationRequest do
  @moduledoc """
  Changeset hook to send a validation request
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationRequest

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    Changeset.before_transaction(changeset, &send_validation_request(&1, ctx), append?: true)
  end

  defp send_validation_request(%Changeset{data: original_validation_request} = changeset, %{actor: actor, tenant: tenant}) do
    validation_request = Ash.load!(original_validation_request, [:collection])

    case Collection.validate(validation_request, actor: actor, authorize?: false, tenant: tenant) do
      {:ok, validation_request} -> add_success(changeset, validation_request, tenant)
      {:error, error} -> add_error(changeset, error, validation_request)
    end
  end

  defp add_error(changeset, error, validation_request) do
    Logger.warning("Error while sending validation request: #{inspect(error)}")
    ValidationRequest.set_failed(validation_request)
    Changeset.add_error(changeset, error)
  end

  defp add_success(changeset, validation_request, tenant) do
    validation_request = ValidationRequest.get_by_id!(validation_request.id, tenant: tenant)

    Logger.info("Successfully sent validation request with #{validation_request.processed_rows_count} records")

    changeset
  end
end
