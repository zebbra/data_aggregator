defmodule DataAggregatorWeb.Components.Breadcrumbs do
  @moduledoc """
  Breadcrumbs component.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]

  @doc """
  Renders a list of breadcrumbs.
  """
  attr :class, :string, default: "text-sm", doc: "the breadcrumbs class"
  attr :items, :list, default: [], doc: "the list of breadcrumbs items"

  def breadcrumbs(assigns) do
    assigns = assign(assigns, length: length(assigns[:items]))

    ~H"""
    <nav aria-label="Breadcrumb" class={["breadcrumbs no-scrollbar py-0 sm:snap-x", @class]}>
      <ol role="list">
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <li class={["sm:snap-start", li_class(index, @length)]}>
            <.link navigate={item[:link]} aria-current={current_page?(index, @length)}>
              <.icon
                :if={index == @length - 2}
                name="hero-arrow-left-micro text-primary mr-1 sm:hidden"
              />
              <%= item[:label] %>
            </.link>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  defp current_page?(index, length) do
    if index == length - 1, do: "page"
  end

  defp li_class(_index, 1) do
    nil
  end

  defp li_class(index, length) do
    if index != length - 2,
      do: "!hidden sm:!flex",
      else: "max-sm:text-primary max-sm:before:!content-[] max-sm:font-bold"
  end
end
