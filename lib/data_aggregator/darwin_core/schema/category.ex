defmodule DataAggregator.DarwinCore.Schema.Category do
  @moduledoc """
  A Darwin Core category.
  """

  alias __MODULE__
  alias Ash.Resource.Attribute

  defstruct [:name, attributes: [], description: nil]

  @type t :: %__MODULE__{
          name: atom(),
          attributes: [Attribute.t()],
          description: String.t()
        }

  @spec prefixed_attributes(t) :: [Attribute.t()]
  def prefixed_attributes(%Category{attributes: attributes} = category) do
    for attribute <- attributes do
      prefixed_name = prefixed_attribute_name(category, attribute)
      %Attribute{attribute | name: prefixed_name}
    end
  end

  def prefixed_attribute_name(%Category{name: prefix}, %Attribute{name: name}) do
    String.to_atom("#{prefix}_#{name}")
  end
end
