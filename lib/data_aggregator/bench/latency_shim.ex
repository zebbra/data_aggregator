defmodule DataAggregator.Bench.LatencyShim do
  @moduledoc """
  Generates a delegate module that sleeps for `BENCH_STUB_LATENCY_MS` ms before
  each call and then forwards to the given stub module. Used by
  `DataAggregator.Bench.Stubs` when latency injection is enabled.

  ## Usage

      defmodule DataAggregator.Bench.LatencyShims.Gbif do
        use DataAggregator.Bench.LatencyShim, target: DataAggregator.Gbif.RestAPIStub
      end

  The shim mirrors every public function of `:target` with the same arity.
  Latency is read per-call (not captured at compile time), so you can change
  `BENCH_STUB_LATENCY_MS` between runs without recompiling.
  """

  defmacro __using__(opts) do
    target = Keyword.fetch!(opts, :target)
    target_module = Macro.expand(target, __CALLER__)

    case Code.ensure_compiled(target_module) do
      {:module, _} ->
        functions =
          for {name, arity} <- target_module.__info__(:functions) do
            args = Macro.generate_arguments(arity, __MODULE__)

            quote do
              def unquote(name)(unquote_splicing(args)) do
                DataAggregator.Bench.LatencyShim.__sleep__()
                unquote(target_module).unquote(name)(unquote_splicing(args))
              end
            end
          end

        quote do
          (unquote_splicing(functions))
        end

      _ ->
        quote do
          @moduledoc false
        end
    end
  end

  @env "BENCH_STUB_LATENCY_MS"

  @doc false
  def __sleep__ do
    case System.get_env(@env) do
      nil -> :ok
      "" -> :ok
      "0" -> :ok
      value -> Process.sleep(String.to_integer(value))
    end
  end

  def enabled? do
    case System.get_env(@env) do
      nil -> false
      "" -> false
      "0" -> false
      _ -> true
    end
  end
end
