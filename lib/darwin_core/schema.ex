defmodule DarwinCore.Schema do
  alias DarwinCore.Field

  def fields do
    [
      %Field{name: "test", type: :string, required?: false}
    ]
  end
end
