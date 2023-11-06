defmodule DataAggregator.Data.Resources.TypeCaster do
  @moduledoc """
  casts strings to given types
  """

  def cast(value, :atom) when is_nil(value) do
    value
  end

  def cast(value, :integer) do
    case value do
      nil -> nil
      _ -> String.to_integer(inspect(value))
    end
  end

  def cast(value, :float) do
    case value do
      nil -> nil
      _ -> String.to_float(inspect(value))
    end
  end

  def cast(value, :string) do
    value
  end

  def cast(value, :boolean) do
    case value do
      nil -> nil
      _ -> String.to_existing_atom(inspect(value)) == true
    end
  end
end
