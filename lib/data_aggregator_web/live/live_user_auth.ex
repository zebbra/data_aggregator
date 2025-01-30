defmodule DataAggregatorWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  use DataAggregatorWeb, :verified_routes

  import DataAggregator.Accounts.Helpers
  import Phoenix.Component

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/datasets")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_collection_administrator_required, _params, _session, socket) do
    if has_role?(socket.assigns[:current_user], ["collection_administrator", "admin"]) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/datasets")}
    end
  end

  def on_mount(:live_data_digitizer_required, _params, _session, socket) do
    if has_role?(socket.assigns[:current_user], ["data_digitizer", "admin"]) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/datasets")}
    end
  end

  def on_mount(:password_set_required, _params, _session, socket) do
    user = Ash.load!(socket.assigns[:current_user], :password_set?)

    if user.password_set? do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/set_password")}
    end
  end

  def on_mount(:terms_accepted_required, _params, _session, socket) do
    user = Ash.load!(socket.assigns[:current_user], :terms_accepted?)

    if user.terms_accepted? do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/terms")}
    end
  end

  def on_mount(:terms_not_accepted_required, _params, _session, socket) do
    user = Ash.load!(socket.assigns[:current_user], :terms_accepted?)

    if user.terms_accepted? do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, socket}
    end
  end
end
