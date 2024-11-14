defmodule DataAggregator.CounterTest do
  use ExUnit.Case, async: true

  alias DataAggregator.Counter

  @backend_opts [
    [backend: DataAggregator.Counter.Inline],
    [backend: DataAggregator.Counter.Async, interval: 100]
  ]

  for opts <- @backend_opts do
    test "counter with #{inspect(opts)}" do
      {:ok, tracker} = Agent.start_link(fn -> 0 end)
      callback_fn = fn count -> Agent.update(tracker, &(&1 + count)) end

      {:ok, counter} = Counter.start(callback_fn, unquote(opts))

      Counter.increment(counter)
      Counter.increment(counter, 2)

      Process.sleep(200)
      assert Agent.get(tracker, & &1) == 3

      assert 1
             |> Stream.from_index()
             |> Counter.count_each(counter)
             |> Enum.take(3) == [1, 2, 3]

      assert Counter.count_each([1, 2, 3], counter) == [1, 2, 3]
      Counter.increment(counter, 1)

      Counter.stop(counter)

      assert Agent.get(tracker, & &1) == 10
    end
  end
end
