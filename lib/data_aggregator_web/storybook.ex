defmodule DataAggregatorWeb.Storybook do
  @moduledoc false

  use PhoenixStorybook,
    otp_app: :data_aggregator,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/storybook.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "data-aggregator",
    themes: [
      default: [name: "Default"],
      dark: [name: "Dark"]
    ]
end
