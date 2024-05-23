defmodule Pagify.Factory.Api do
  @moduledoc false
  use Ash.Api

  resources do
    registry Pagify.Factory.Registry
  end
end
