defmodule Storybook.Collections.Imports do
  use PhoenixStorybook.Index

  def entry("status_badge"), do: [icon: {:fa, "window-restore", :thin}]
end
