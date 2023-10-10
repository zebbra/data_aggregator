defmodule DataAggregator.TaxonomyData.Record2Tag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.TaxonomyData.Record
  alias DataAggregator.TaxonomyData.Tag

  postgres do
    table "records2tags"
    repo DataAggregator.Repo
  end

  relationships do
    belongs_to :record, Record, primary_key?: true, allow_nil?: false
    belongs_to :tag, Tag, primary_key?: true, allow_nil?: false
  end
end
