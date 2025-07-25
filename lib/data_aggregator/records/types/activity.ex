defmodule DataAggregator.Records.Activity do
  @moduledoc """
  Defining an activity that happens on a record
  """

  alias __MODULE__

  defstruct [:name, :actor, :date_time, :content, :source, :index]

  @type t :: %Activity{}
end
