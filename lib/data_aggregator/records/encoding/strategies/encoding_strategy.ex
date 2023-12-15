defprotocol DataAggregator.Records.Encoding.Strategy.EncodingStrategy do
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  @spec encode(list(Record.t())) :: list(EncodedRecord.t())
  def encode(records)
end
