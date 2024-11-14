defmodule DataAggregator.Counter do
  @moduledoc """
  A GenServer that counts events and triggers a callback at a throttled interval.
  """

  import DataAggregator.Guards

  @type ref :: any()
  @type counter :: {module(), ref()}
  @type callback_fn :: (integer -> any)

  @spec start(callback_fn(), Keyword.t()) :: {:ok, counter()} | {:error, term()}
  def start(callback, opts \\ []) do
    {backend, opts} = Keyword.pop(opts, :backend, default_backend())

    case backend.start(callback, opts) do
      {:ok, ref} -> {:ok, {backend, ref}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec stop(counter()) :: :ok
  def stop({backend, ref}) do
    backend.stop(ref)
  end

  @spec increment(counter(), integer()) :: :ok
  def increment({backend, ref}, value \\ 1) do
    backend.increment(ref, value)
  end

  @spec count_each(Enumerable.t(), counter()) :: Enumerable.t()
  def count_each(enum, counter)

  def count_each(enum, counter) when is_list(enum) do
    increment(counter, length(enum))
    enum
  end

  def count_each(stream, counter) when is_stream(stream) do
    Stream.each(stream, fn _ -> increment(counter) end)
  end

  def default_backend do
    :data_aggregator
    |> Application.get_env(__MODULE__, [])
    |> Keyword.fetch!(:backend)
  end
end
