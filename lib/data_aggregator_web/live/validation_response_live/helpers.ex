defmodule DataAggregatorWeb.ValidationResponseLive.Helpers do
  @moduledoc """
  This module contains helper functions for the validation response live view
  """

  def load do
    [:attachment, :error_log, :created_by, :started_by, :duration]
  end
end
