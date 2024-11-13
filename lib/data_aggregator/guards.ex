defmodule DataAggregator.Guards do
  @moduledoc false
  defguard is_stream(stream) when is_struct(stream, Stream)
end
