defmodule DataAggregator.DarwinCore.Schema.DwcAttribute do
  @moduledoc """
  A Darwin Core Attribute Wrapper Struct.
  """

  alias Ash.Resource.Attribute

  defstruct dwc_field: nil, dwc_link: nil, dwca_file: nil, attribute: nil

  @type t :: %__MODULE__{
          dwc_field: String.t(),
          dwc_link: String.t(),
          dwca_file: atom(),
          attribute: Attribute.t()
        }
end
