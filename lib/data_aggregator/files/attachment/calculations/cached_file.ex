defmodule DataAggregator.Files.Attachment.Calculations.CachedFile do
  @moduledoc """
  `Ash.Resource.Calculation` to load the cached file path for an attachment using
  `DataAggregator.Files.Cache`.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.Files.Cache

  @impl Ash.Resource.Calculation
  def calculate(attachments, _opts, _ctx) do
    attachments
    |> Enum.reverse()
    |> Enum.reduce_while([], &reduce_paths/2)
  end

  defp reduce_paths(attachment, paths) do
    case Cache.store(attachment) do
      {:ok, path} -> {:cont, [path | paths]}
      {:error, error} -> {:halt, {:error, error}}
    end
  end
end
