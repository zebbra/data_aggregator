defmodule Pagify.Factory.Registry do
  @moduledoc false
  use Ash.Registry

  entries do
    entry Pagify.Factory.Post
    entry Pagify.Factory.Comment
  end
end
