defmodule DataAggregator.Misc.ThrottledCounter do
  @moduledoc """
  A GenServer that counts events and triggers a callback at a throttled interval.
  """

  use GenServer

  import DataAggregator.Guards

  require Logger

  @type callback_fn :: (integer -> any)

  @default_interval :timer.seconds(1)

  ## Client API

  @spec start(callback_fn, Keyword.t()) :: GenServer.on_start()
  def start(callback, opts \\ []) do
    opts =
      opts
      |> Keyword.put(:callback, callback)
      |> Keyword.put_new(:interval, @default_interval)

    GenServer.start_link(__MODULE__, opts)
  end

  @spec increment(pid(), integer) :: :ok
  def increment(pid, value \\ 1) do
    GenServer.cast(pid, {:increment, value})
  end

  @spec count_each(Enumerable.t(), pid()) :: Enumerable.t()
  def count_each(enum, pid)

  def count_each(enum, pid) when is_list(enum) do
    increment(pid, length(enum))
  end

  def count_each(stream, pid) when is_stream(stream) do
    Stream.each(stream, fn _ -> increment(pid) end)
  end

  @spec stop(pid()) :: :ok
  def stop(pid) do
    Logger.debug("[#{inspect(pid)}] Stopping counter ...")
    GenServer.call(pid, :stop)
  end

  ## Server Callbacks

  def init(opts) do
    callback = Keyword.fetch!(opts, :callback)
    interval = Keyword.fetch!(opts, :interval)

    Logger.debug("[#{inspect(self())}] Starting throttled counter with (interval: #{inspect(interval)})")

    %{count: 0, callback: callback, interval: interval}
    |> schedule_callback()
    |> ok()
  end

  def handle_cast({:increment, value}, %{count: count} = state) do
    state
    |> Map.put(:count, count + value)
    |> noreply()
  end

  def handle_info(:trigger_callback, state) do
    state
    |> trigger_callback()
    |> schedule_callback()
    |> noreply()
  end

  def handle_call(:stop, _from, state) do
    state = trigger_callback(state)
    {:stop, :normal, :ok, state}
  end

  ## Private functions

  defp ok(state), do: {:ok, state}
  defp noreply(state), do: {:noreply, state}

  defp trigger_callback(%{count: 0} = state) do
    state
  end

  defp trigger_callback(%{callback: callback, count: count} = state) when is_function(callback, 1) do
    Logger.debug("[#{inspect(self())}] Triggering counter callback with count: #{count}")
    callback.(count)
    %{state | count: 0}
  end

  defp schedule_callback(state) do
    Process.send_after(self(), :trigger_callback, state.interval)
    state
  end
end
