defmodule DataAggregator.DarwinCore.Resource.Transformers.AddAttributes do
  @moduledoc """
  `Spark.Dsl.Transformer` that adds `DataAggregator.DarwinCore.Schema.prefixed_attributes/0` to the resource.
  """

  use Spark.Dsl.Transformer

  alias Ash.Resource.Attribute
  alias Spark.Dsl.Transformer

  @after_transformers [
    Ash.Resource.Transformers.ValidatePrimaryActions
  ]

  @before_transformers [
    Ash.Resource.Transformers.DefaultAccept,
    Ash.Resource.Transformers.SetTypes
  ]

  def transform(dsl_state) do
    if Transformer.get_persisted(dsl_state, :embedded?, false) do
      {:ok, dsl_state}
    else
      dsl_state |> add_attributes()
    end
  end

  def after?(transformer) when transformer in @after_transformers, do: true
  def after?(_), do: false

  def before?(transformer) when transformer in @before_transformers, do: true
  def before?(_), do: false

  defp add_attributes(dsl_state) do
    DataAggregator.DarwinCore.Schema.prefixed_attributes()
    |> Enum.reduce_while({:ok, dsl_state}, &reduce_attribute/2)
  end

  defp reduce_attribute(%Attribute{} = attribute, {:ok, dsl_state}) do
    case add_attribute(dsl_state, attribute) do
      {:ok, _} = acc -> {:cont, acc}
      {:error, _} = acc -> {:halt, acc}
    end
  end

  defp add_attribute(dsl_state, %Attribute{} = attribute) do
    with {:ok, entity} <- build_attribute(attribute) do
      {:ok, Transformer.add_entity(dsl_state, [:attributes], entity)}
    end
  end

  defp build_attribute(%Attribute{} = attribute) do
    opts = [
      name: attribute.name,
      type: attribute.type,
      description: attribute.description || "",
      allow_nil?: !!attribute.allow_nil?
    ]

    Transformer.build_entity(Ash.Resource.Dsl, [:attributes], :attribute, opts)
  end
end
