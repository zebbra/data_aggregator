defmodule DataAggregator.DarwinCore.Schema.Docs do
  @moduledoc false

  alias DataAggregator.DarwinCore.Schema.Category

  def schema_docs(categories) do
    """
    <!-- tabs-open -->

    #{Enum.map(categories, &category_docs/1)}

    <!-- close -->
    """
  end

  defp category_docs(%Category{name: name, attributes: attributes, description: description}) do
    """
    ### #{name |> Atom.to_string() |> String.upcase()}

    #### Description

    #{description || "*No description provided*"}

    #### Attributes

    #{attributes_table(attributes)}

    > #### **Note:** {: .info}
    >
    > The record attributes are prefixed with `#{name}_` (e.g. `#{name}_#{List.first(attributes).name}`)
    """
  end

  defp attributes_table(attributes) do
    """
    | Name | Type | Required | Description |
    |------|------|----------|-------------|
    #{Enum.map(attributes, &attributes_table_row/1)}
    """
  end

  defp attributes_table_row(attribute) do
    cols = [
      "`#{attribute.name}`",
      "`#{attribute.type}`",
      if(attribute.allow_nil?, do: "No", else: "Yes"),
      attribute.description
    ]

    """
    | #{Enum.join(cols, " | ")} |
    """
  end
end
