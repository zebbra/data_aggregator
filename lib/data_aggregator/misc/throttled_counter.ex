defmodule DataAggregator.Misc.ThrottledCounter do
  @moduledoc false
  use GenServer

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

  def increment(pid, value \\ 1) do
    GenServer.cast(pid, {:increment, value})
  end

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
    Logger.debug("[#{inspect(self())}] Not triggering callback")
    state
  end

  defp trigger_callback(%{callback: callback, count: count} = state) when is_function(callback, 1) do
    Logger.debug("[#{inspect(self())}] Triggering callback with count: #{count}")
    callback.(count)
    %{state | count: 0}
  end

  defp schedule_callback(state) do
    Process.send_after(self(), :trigger_callback, state.interval)
    state
  end
end
