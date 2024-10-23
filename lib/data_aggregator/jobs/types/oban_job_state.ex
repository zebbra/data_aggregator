defmodule DataAggregator.Jobs.Types.ObanJobState do
  @moduledoc """
  Enum to define the states an Oban job can be in.
  """

  use Ash.Type.NewType, subtype_of: :atom

  @impl Ash.Type
  def storage_type(_constraints), do: :oban_job_state
end
