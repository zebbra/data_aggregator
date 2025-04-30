defmodule DataAggregator.DarwinCore.Schema.CollectionAttribute do
  @moduledoc """
  A Wrapper Struct for Attributes we take from the collection
  """

  defstruct dwc_field: nil, dwc_link: nil, dwca_file: nil, name: nil, collection_field: nil

  @type t :: %__MODULE__{
          dwc_field: String.t(),
          dwc_link: String.t(),
          dwca_file: atom(),
          name: atom(),
          collection_field: atom()
        }
end
