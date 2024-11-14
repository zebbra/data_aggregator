defmodule DataAggregator.Counter.Backend do
  @moduledoc false
  alias DataAggregator.Counter

  @callback start(Counter.callback_fn(), Keyword.t()) :: {:ok, Counter.ref()} | {:error, term()}
  @callback increment(Counter.ref(), integer) :: any()
  @callback stop(Counter.ref()) :: :ok

  defmacro __using__(_) do
    quote do
      @behaviour DataAggregator.Counter.Backend
    end
  end
end
