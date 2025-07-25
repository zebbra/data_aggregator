defmodule DataAggregator.Files.Store do
  @moduledoc """
  Module for storing files using Waffle.
  """

  use Waffle.Definition

  alias DataAggregator.Files.Attachment

  @acl :private

  def storage_dir(_version, {_file, %Attachment{id: id}}) do
    "files/#{id}"
  end
end
