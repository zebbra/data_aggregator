defmodule DataAggregatorWeb.AuthOverrides do
  @moduledoc false
  use AshAuthentication.Phoenix.Overrides

  alias AshAuthentication.Phoenix.Components

  override Components.MagicLink do
    # lets hide the magic link in the sign in page
    # we only use magic links for first time login
    set :root_class, "hidden"
  end

  override Components.Banner do
    set :root_class,
        "flex items-center w-full mx-auto py-2 justify-between max-w-sm flex-row-reverse"

    set :text, "Data Aggregator"
    set :text_class, "text-xl font-semibold"
    set :image_url, "/images/logo.png"
    set :image_class, "size-12"
  end

  override Components.Password.Input do
    set :field_class, "form-control w-full first-of-type:mt-0 mt-2"
    set :label_class, "label"
    set :input_class, "input input-bordered w-full"
    set :input_class_with_error, "input input-bordered w-full input-error"
    set :submit_class, "btn btn-primary btn-block"
    set :input_debounce, 350
  end
end
