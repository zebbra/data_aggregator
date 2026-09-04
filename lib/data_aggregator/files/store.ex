defmodule DataAggregator.Files.Store do
  @moduledoc """
  Module for storing files using Waffle.

  Note that no `@acl` is set on purpose. S3 uploads go through
  `DataAggregator.Files.S3Storage`, which never sends a canned ACL, because SWITCH
  Ceph rejects `x-amz-acl` with `403 AccessDenied`. Objects stay private through the
  bucket policy and are read via the signed URLs from `Attachment.Calculations.Url`.

  See https://github.com/zebbra/data_aggregator/issues/1099
  """

  use Waffle.Definition

  alias DataAggregator.Files.Attachment

  def storage_dir(_version, {_file, %Attachment{id: id}}) do
    "files/#{id}"
  end
end
