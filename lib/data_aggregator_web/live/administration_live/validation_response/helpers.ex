defmodule DataAggregatorWeb.AdministrationLive.ValidationResponse.Helpers do
  @moduledoc """
  This module contains helper functions for the validation response live view
  """

  def load do
    [:attachment, :error_log, :created_by, :started_by, :duration, :validation_progress]
  end

  def can_edit?(nil), do: false
  def can_edit?(validation_response), do: validation_response.state in [:pending]

  def can_rerun?(nil), do: false
  def can_rerun?(validation_response), do: validation_response.state in [:cancelled]
end
