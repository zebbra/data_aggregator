defmodule DataAggregatorWeb.Components.AsyncData do
  @moduledoc """
  Renders content based on a `Phoenix.LiveView.AsyncResult`.
  """

  use Phoenix.Component

  alias DataAggregatorWeb.Components.Icon

  @doc """
  Renders content based on an `AsyncResult` state.

  Handles three states:
  - `:loading` - shows the `loading` slot (spinner by default)
  - `:ok` - shows the inner block via `:let`
  - `:failed` - shows the `failed` slot

  ## Examples

      <.async_data :let={counts} async_result={@counts}>
        <:loading>
          <.skeleton class="h-8 w-24" />
        </:loading>
        <:failed :let={_error}>
          <span class="text-error">Failed to load</span>
        </:failed>
        <span class="text-2xl font-bold">{counts.total}</span>
      </.async_data>
  """
  attr :async_result, Phoenix.LiveView.AsyncResult, required: true

  slot :loading
  slot :failed
  slot :inner_block, required: true

  def async_data(assigns) do
    ~H"""
    <%= cond do %>
      <% @async_result.ok? -> %>
        {render_slot(@inner_block, @async_result.result)}
      <% @async_result.failed -> %>
        <%= if @failed != [] do %>
          {render_slot(@failed, @async_result.failed)}
        <% else %>
          <.default_failed />
        <% end %>
      <% true -> %>
        <%= if @loading != [] do %>
          {render_slot(@loading)}
        <% else %>
          <.default_loading />
        <% end %>
    <% end %>
    """
  end

  defp default_loading(assigns) do
    ~H"""
    <span class="loading loading-spinner loading-sm"></span>
    """
  end

  defp default_failed(assigns) do
    ~H"""
    <span class="text-error flex items-center gap-1">
      <Icon.icon name="hero-exclamation-triangle-mini" class="size-4" />
      <span>Failed to load</span>
    </span>
    """
  end

  @doc """
  Renders a skeleton loading placeholder using daisyUI's `skeleton` class.

  ## Examples

      <.skeleton class="h-8 w-24" />
      <.skeleton class="h-4 w-full rounded" />
  """
  attr :class, :string, default: "h-4 w-20"
  attr :rest, :global

  def skeleton(assigns) do
    ~H"""
    <div class={["skeleton", @class]} {@rest}></div>
    """
  end
end
