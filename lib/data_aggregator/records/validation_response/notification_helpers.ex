defmodule DataAggregator.Records.ValidationResponse.NotificationHelpers do
  @moduledoc false
  alias Ash.Changeset
  alias DataAggregator.Api
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Types

  require Logger

  @doc """
  Notifies the infospecies team about the result of the validation import
  """
  @spec notify_infospecies(Changeset.t()) :: Changeset.t()
  def notify_infospecies(changeset) do
    with {:ok, response} <-
           notify_infospecies_with_validation_result(changeset.data),
         :ok <- ensure_status(response) do
      changeset
    else
      {:error, error} ->
        Logger.error("Could not notify Infospecies about validation response result: #{inspect(error)}")

        # For now we just log the error and return the changeset without adding an error
        # add_error(changeset, error)
        changeset
    end
  end

  @spec notify_infospecies_with_validation_result(ValidationResponse.t()) :: Types.Api.response()
  defp notify_infospecies_with_validation_result(validation) do
    Logger.info("Notifying infospecies about validation result")

    Req.post(
      url: Api.Helpers.infospecies_validation_notification_url(),
      json: validation_result_payload(validation)
    )
  end

  @spec validation_result_payload(ValidationResponse.t()) :: map()
  defp validation_result_payload(%ValidationResponse{error_log_id: nil} = validation_response),
    do: %{
      "source_file" => validation_response.file_url,
      "success_count" => validation_response.rows_validated_count,
      "error_count" => validation_response.rows_invalid_count,
      "error_log_url" => ""
    }

  @spec validation_result_payload(ValidationResponse.t()) :: map()
  defp validation_result_payload(validation_response) do
    validation_response = Ash.load!(validation_response, [:error_log], lazy?: true)
    error_log = Ash.load!(validation_response.error_log, [:url], lazy?: true)

    %{
      "success_count" => validation_response.rows_validated_count,
      "error_count" => validation_response.rows_invalid_count,
      "error_log_url" => error_log.url
    }
  end

  @spec ensure_status(map()) :: :ok | {:error, String.t()}
  defp ensure_status(%{status: 200}), do: :ok

  defp ensure_status(response) do
    msg =
      "No valid response (status #{response.status}) from Infospecies API while notifying about processed validation response: #{inspect(response)}"

    {:error, msg}
  end
end
