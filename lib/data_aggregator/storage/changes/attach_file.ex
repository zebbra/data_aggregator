defmodule DataAggregator.Storage.Changes.AttachFile do
  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(changeset, _opts, _) do
    src_path = Changeset.get_argument(changeset, :path)

    dst_path =
      Path.join([:code.priv_dir(:data_aggregator), "static", "uploads", Path.basename(src_path)])

    Logger.info("Uploading file from #{src_path} to #{dst_path} ...")
    File.cp!(src_path, dst_path)

    changeset |> Changeset.change_attribute(:url, dst_path)
  end
end
