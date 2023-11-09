defmodule DataAggregator.DarwinCore.Schema.Category do
  @moduledoc """
  A Darwin Core category.
  """

  defstruct [:name, attributes: [], description: nil]

  alias Ash.Resource.Attribute

  @type t :: %__MODULE__{
          name: atom(),
          attributes: [Attribute.t()],
          description: String.t()
        }

  @spec prefixed_attributes(t) :: [Attribute.t()]
  def prefixed_attributes(%__MODULE__{name: name, attributes: attributes}) do
    for attribute <- attributes do
      prefixed_name = "#{name}_#{attribute.name}" |> String.to_atom()
      %Attribute{attribute | name: prefixed_name}
    end
  end
end
