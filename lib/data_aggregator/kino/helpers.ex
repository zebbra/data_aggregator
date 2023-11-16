if Code.ensure_loaded?(Kino) do
  defmodule DataAggregator.Kino.Helpers do
    @moduledoc false

    @hidden_resource_keys [
      :calculations,
      :aggregates,
      :__meta__,
      :__metadata__,
      :__order__,
      :__lateral_join_source__
    ]

    def render_struct(struct, opts \\ []) do
      %module{} = struct
      name = module |> to_string() |> String.replace_prefix("Elixir.", "")
      opts = opts |> Keyword.put_new(:name, name)

      default_keys = struct |> Map.from_struct() |> Map.keys()
      default_keys = default_keys -- @hidden_resource_keys
      {keys, opts} = Keyword.pop(opts, :keys, default_keys)

      keys
      |> Enum.map(&%{"key" => &1, "value" => Map.get(struct, &1)})
      |> Kino.DataTable.new(opts)
    end
  end
end
