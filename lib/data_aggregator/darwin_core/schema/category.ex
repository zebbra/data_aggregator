defmodule DataAggregator.DarwinCore.Schema.Category do
  @moduledoc """
  A Darwin Core category.
  """

  defstruct [:name, label: "", attributes: [], description: nil]

  alias Ash.Resource.Attribute

  @type t :: %__MODULE__{
          name: atom(),
          attributes: [Attribute.t()],
          description: String.t()
        }

  alias __MODULE__

  @spec prefixed_attributes(t) :: [Attribute.t()]
  def prefixed_attributes(%Category{attributes: attributes} = category) do
    for attribute <- attributes do
      prefixed_name = prefixed_attribute_name(category, attribute)
      %Attribute{attribute | name: prefixed_name}
    end
  end

  def prefixed_attribute_name(%Category{name: prefix}, %Attribute{name: name}) do
    "#{prefix}_#{name}" |> String.to_atom()
  end
end
