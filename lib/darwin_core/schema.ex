defmodule DarwinCore.Schema do
  @moduledoc """
  Darwin Core Schema
  """

  alias DarwinCore.Field

  def fields do
    [
      %Field{name: "test", type: :string, required?: false}
    ]
  end
end
