defmodule Pagify.Factory.Domain do
  @moduledoc false
  use Ash.Domain,
    validate_config_inclusion?: false

  resources do
    resource Pagify.Factory.Comment
    resource Pagify.Factory.Post
  end
end
