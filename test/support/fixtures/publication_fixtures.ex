defmodule DataAggregator.PublicationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  Consumer entities via the `DataAggregator.Platform` context.
  """

  alias DataAggregator.Platform.Publication.Consumer
  alias DataAggregator.Platform.Publication.Export

  @consumers_defaults %{
    name: "gbif.org",
    publication_type: :gbif
  }

  @export_defaults %{
    name: "gbif.org - Export"
  }

  @doc """
  Generate a consumer.
  """
  def consumer_fixture(attrs \\ %{}) do
    @consumers_defaults
    |> Map.merge(attrs)
    |> Consumer.create!()
  end

  @doc """
  Generate an export.
  """
  def export_fixture(attrs \\ %{}) do
    @export_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:consumer, fn -> consumer_fixture() end)
    |> Map.put(:records, [])
    |> Export.create!()
  end
end
