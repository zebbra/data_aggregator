defmodule DataAggregatorWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use DataAggregatorWeb, :controller
      use DataAggregatorWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images docs favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: DataAggregatorWeb.Layouts]

      import Plug.Conn
      import DataAggregatorWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {DataAggregatorWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def page do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(page_helpers())
    end
  end

  defp html_helpers do
    quote do
      use DataAggregatorWeb.ViewportHelpers

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import DataAggregatorWeb.CoreComponents
      import DataAggregatorWeb.HeadlessComponents
      import DataAggregatorWeb.Headless.Dialog, only: [dialog_title: 1, dialog_description: 1]
      import DataAggregatorWeb.Gettext
      import DataAggregatorWeb.Page

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      import DataAggregatorWeb.Helpers

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  defp page_helpers do
    quote do
      # Core UI components and translation
      import DataAggregatorWeb.CoreComponents, only: [icon: 1]
      import DataAggregatorWeb.HeadlessComponents
      import DataAggregatorWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: DataAggregatorWeb.Endpoint,
        router: DataAggregatorWeb.Router,
        statics: DataAggregatorWeb.static_paths()
    end
  end

  @doc ~S"""
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
