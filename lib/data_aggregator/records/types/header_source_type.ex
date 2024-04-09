defmodule DataAggregator.Records.HeaderSourceType do
  @moduledoc """
  Enum to define sources of column headers which can be choosen for data exporting.
  """

  use Ash.Type.Enum, values: [:collection_mapping, :dwc_attributes, :custom_selection]

  alias __MODULE__

  defstruct []

  @type t :: %HeaderSourceType{}
end
