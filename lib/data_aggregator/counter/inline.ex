defmodule DataAggregator.Counter.Inline do
  @moduledoc false

  use DataAggregator.Counter.Backend

  alias DataAggregator.Counter
  alias DataAggregator.Counter.Backend

  @spec start(Counter.callback_fn(), Keyword.t()) :: {:ok, Counter.callback_fn()}
  @impl Backend
  def start(callback, _opts), do: {:ok, callback}

  @spec increment(Counter.callback_fn(), integer()) :: any()
  @impl Backend
  def increment(callback, value), do: callback.(value)

  @spec stop(any()) :: :ok
  @impl Backend
  def stop(_), do: :ok
end
