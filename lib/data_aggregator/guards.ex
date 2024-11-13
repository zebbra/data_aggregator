defmodule DataAggregator.Guards do
  @moduledoc false
  defguard is_stream(stream) when is_struct(stream, Stream) or is_function(stream, 2)
end
