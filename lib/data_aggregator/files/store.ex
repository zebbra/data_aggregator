defmodule DataAggregator.Files.Store do
  @moduledoc """
  Module for storing files using Waffle.
  """

  use Waffle.Definition

  @acl :private

  def storage_dir(_version, {_file, attachment_id}) do
    "files/#{attachment_id}"
  end
end
