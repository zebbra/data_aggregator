defmodule DataAggregator.Files.Store do
  use Waffle.Definition

  @acl :private

  def storage_dir(_version, {_file, attachment_id}) do
    "files/#{attachment_id}"
  end
end
