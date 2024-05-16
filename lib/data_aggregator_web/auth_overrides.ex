defmodule DataAggregatorWeb.AuthOverrides do
  @moduledoc false
  use AshAuthentication.Phoenix.Overrides

  alias AshAuthentication.Phoenix.Components

  override Components.Banner do
    set :image_url, "/images/sign_in_logo.png"
  end

  override Components.Password.SignInForm do
    set :root_class, nil
    set :label_class, "mt-2 mb-4 text-2xl tracking-tight font-bold text-gray-900 dark:text-white"
    set :form_class, nil
    set :slot_class, "my-4"
    set :disable_button_text, "Signing in ..."
  end

  override Components.Password.Input do
    set :field_class, "form-control"
    set :label_class, "label"

    set :input_class, "input input-bordered w-full"

    set :input_class_with_error, """
    appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md
    shadow-sm placeholder-gray-400 focus:outline-none border-red-400 sm:text-sm
    dark:text-black
    """

    set :submit_class, "btn btn-primary btn-block"

    set :error_ul, "text-red-400 font-light my-3 italic text-sm"
    set :error_li, nil
    set :input_debounce, 350
  end
end
