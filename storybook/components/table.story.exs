defmodule Storybook.Components.Table do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Table.table/1
  def imports, do: [{Components.Dropdown, [dropdown: 1]}, {Components.Icon, [icon: 1]}]
  def aliases, do: [Storybook.Components.Table.User]

  def variations do
    [
      %Variation{
        id: :table,
        attributes: %{
          rows: {:eval, rows()}
        },
        slots: [cols()]
      },
      %Variation{
        id: :with_row_click,
        attributes: %{
          rows: {:eval, rows()},
          row_click: {:eval, noop()}
        },
        slots: [cols()]
      },
      %Variation{
        id: :with_col_class,
        attributes: %{
          rows: {:eval, rows()}
        },
        slots: [
          ~s"""
          <:col :let={user} label="Id" class="font-semibold">
            <%= user.id %>
          </:col>
          <:col :let={user} label="User name" class="text-right">
            <%= user.username %>
          </:col>
          """
        ]
      },
      %Variation{
        id: :with_action,
        attributes: %{
          rows: {:eval, rows()},
          row_click: {:eval, noop()}
        },
        slots: [cols(), action()]
      }
    ]
  end

  def action do
    """
    <:action :let={user} class="-mx-3 -my-1.5 sm:-mx-2.5">
      <.dropdown id={"user_" <> to_string(user.id)} class="dropdown-left">
        <:summary>
          <summary class="btn btn-sm btn-ghost btn-square text-base-content/75 hover:text-base-content">
            <.icon name="hero-ellipsis-horizontal-micro" />
          </summary>
        </:summary>
        <ul class="dropdown-content z-10 menu menu-sm bg-base-200 rounded-box border-black-white/10 w-28 gap-1 border p-2 shadow-2xl">
          <li><button type="button" class="hover:bg-primary hover:text-primary-content">View</button></li>
          <li><button type="button" class="hover:bg-primary hover:text-primary-content">Edit</button></li>
          <li><button type="button" class="hover:bg-primary hover:text-primary-content">Delete</button></li>
        </ul>
      </.dropdown>
    </:action>
    """
  end

  def rows do
    """
    [
      %User{id: 1, username: "jose"},
      %User{id: 2, username: "chris"}
    ]
    """
  end

  def cols do
    """
    <:col :let={user} label="Id">
      <%= user.id %>
    </:col>
    <:col :let={user} label="User name">
      <%= user.username %>
    </:col>
    """
  end

  def noop do
    """
    fn _ -> JS.dispatch("storybook:console:log") end
    """
  end
end

defmodule Storybook.Components.Table.User do
  defstruct [:id, :username]
end
