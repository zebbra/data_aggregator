defmodule Storybook.Imports do
  @moduledoc false
  use PhoenixStorybook.Index

  def entry("status_badge"), do: [icon: {:fa, "window-restore", :thin}]
end
