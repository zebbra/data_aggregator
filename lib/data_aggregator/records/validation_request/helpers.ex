defmodule DataAggregator.Records.ValidationRequest.Helpers do
  @moduledoc false

  @spec center_specific_filter(atom()) :: map()
  def center_specific_filter(center) do
    %{
      encoded_record: %{swiss_species: %{center: %{eq: center}}}
    }
  end
end
