defmodule DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy do
  @moduledoc """
  Encoding strategy for GBIF Taxonomy
  """

  @input_attributes [:tax_scientific_name, :tax_scientific_name_authorship]
  @output_attributes [:tax_kingdom, :tax_phylum, :tax_class, :tax_order, :tax_family, :tax_genus]
  @catalog :gbif_taxonomy

  @spec input_attributes() :: list(atom())
  def input_attributes, do: @input_attributes

  @spec output_attributes() :: list(atom())
  def output_attributes, do: @output_attributes

  @spec catalog() :: atom()
  def catalog, do: @catalog
end

alias DataAggregator.Records.EncodedRecord
alias DataAggregator.Records.Encoding.Strategy.EncodingStrategy
alias DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy

defimpl EncodingStrategy, for: GbifTaxonomyStrategy do
  @impl true
  def encode(_records) do
    _input_attributes = GbifTaxonomyStrategy.input_attributes()
    _output_attributes = GbifTaxonomyStrategy.output_attributes()
    _catalog = GbifTaxonomyStrategy.catalog()

    # query the gbif taxanomy api and return a list of encoded records

    [%EncodedRecord{}]
  end
end
