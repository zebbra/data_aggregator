defmodule DataAggregator.DarwinCore.Schema.Category do
  @moduledoc """
  A Darwin Core category.
  """

  alias __MODULE__
  alias Ash.Resource.Attribute
  alias DataAggregator.DarwinCore.Schema.DwcAttribute

  defstruct [:name, label: "", dwc_attributes: [], description: nil]

  @type t :: %__MODULE__{
          name: atom(),
          dwc_attributes: [DwcAttribute.t()],
          description: String.t()
        }

  @spec prefixed_attributes(t) :: [Attribute.t()]
  def prefixed_attributes(%Category{dwc_attributes: dwc_attributes} = category) do
    for dwc_attribute <- dwc_attributes do
      attribute = dwc_attribute.attribute

      prefixed_name = prefixed_attribute_name(category, attribute)
      %Attribute{attribute | name: prefixed_name}
    end
  end

  @spec prefixed_attribute_names_and_dwc_fields(t) :: [{atom(), String.t()}]
  def prefixed_attribute_names_and_dwc_fields(%Category{dwc_attributes: dwc_attributes} = category) do
    for dwc_attribute <- dwc_attributes do
      prefixed_name = prefixed_attribute_name(category, dwc_attribute.attribute)

      dwc_field = Map.get(dwc_attribute, :dwc_field)

      dwc_field =
        if dwc_field != nil,
          do: dwc_field,
          else: dwc_attribute.attribute.name

      {prefixed_name, dwc_field}
    end
  end

  def prefixed_attribute_name(%Category{name: prefix}, %Attribute{name: name}) do
    String.to_atom("#{prefix}_#{name}")
  end
end
