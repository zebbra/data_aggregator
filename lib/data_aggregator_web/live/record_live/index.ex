defmodule DataAggregatorWeb.RecordLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  defstruct [:id, :first_name, :last_name, :email, :age]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_id: 20,
       selected_user: nil,
       users: seed_users()
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="users" open={@selected_user != nil}>
      <div class="grid gap-y-4">
        <.header>
          <%= ~t"List of users"m %>
          <:subtitle><%= ~t"Feel free to add any missing user!"m %></:subtitle>
          <:actions>
            <button type="button" class="btn btn-neutral" onclick="user_modal.showModal()">
              <%= ~t"Create user"m %>
            </button>
          </:actions>
        </.header>
        <div class="overflow-x-auto pb-4">
          <.table
            id="user-table"
            rows={@users}
            row_click={
              fn user ->
                JS.push("select_user", value: %{id: user.id})
              end
            }
          >
            <:col :let={user} label="Id" class="font-semibold">
              <%= user.id %>
            </:col>
            <:col :let={user} label={~t"First name"m}>
              <%= user.first_name %>
            </:col>
            <:col :let={user} label={~t"Last name"m}>
              <%= user.last_name %>
            </:col>
            <:col :let={user} label={~t"Email"m}>
              <%= user.email %>
            </:col>
            <:col :let={user} label={~t"Age"m} class="text-right">
              <%= user.age %>
            </:col>

            <:action :let={user} class="-mx-3 -my-1.5 sm:-mx-2.5">
              <.dropdown id={"user-#{user.id}"} class="dropdown-left">
                <:summary>
                  <summary class="btn btn-sm btn-ghost btn-square text-base-content/75 hover:text-base-content">
                    <.icon name="hero-ellipsis-horizontal-micro" />
                  </summary>
                </:summary>
                <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-white/5 outline-black/5 z-10 w-28 gap-1 border p-2 shadow-lg outline outline-1">
                  <li>
                    <button
                      type="button"
                      class="hover:bg-primary hover:text-primary-content"
                      phx-click={JS.push("select_user", value: %{id: user.id})}
                    >
                      <%= ~t"View"m %>
                    </button>
                  </li>
                  <li>
                    <button type="button" class="hover:bg-primary hover:text-primary-content">
                      <%= ~t"Edit"m %>
                    </button>
                  </li>
                  <li>
                    <.link
                      phx-click={JS.push("delete", value: %{id: user.id})}
                      class="hover:bg-primary hover:text-primary-content"
                      data-confirm={~t"Are you sure?"m}
                    >
                      <%= ~t"Delete"m %>
                    </.link>
                  </li>
                </ul>
              </.dropdown>
            </:action>
          </.table>
        </div>
      </div>
      <:secondary>
        <div class="bg-base-100 border-white/5 outline-black/5 divide-base-content/10 min-h-dvh flex w-96 flex-col divide-y border-l outline outline-1 md:ml-6">
          <div :if={@selected_user} class="flex min-h-0 flex-1 flex-col overflow-y-scroll p-4">
            <.header>
              <%= ~t"User details"m %>
              <:subtitle><%= full_name(@selected_user) %></:subtitle>
              <:actions>
                <button
                  type="button"
                  class="btn btn-square btn-ghost drawer-button"
                  phx-click={JS.push("select_user", value: %{id: nil})}
                >
                  <.icon name="hero-x-mark-mini" class="size-5 md:size-6" />
                </button>
              </:actions>
            </.header>

            <.list>
              <:item title="ID">
                <%= @selected_user.id %>
              </:item>
              <:item title={~t"First name"m}>
                <%= @selected_user.first_name %>
              </:item>
              <:item title={~t"Last name"m}>
                <%= @selected_user.last_name %>
              </:item>
              <:item title={~t"Email"m}>
                <%= @selected_user.email %>
              </:item>
              <:item title={~t"Age"m}>
                <%= @selected_user.age %>
              </:item>
            </.list>
          </div>
          <div class="flex flex-shrink-0 justify-end p-4">
            <button
              type="button"
              class="btn btn-neutral"
              phx-click={JS.push("select_user", value: %{id: nil})}
            >
              <%= ~t"Close"m %>
            </button>
          </div>
        </div>
      </:secondary>
      <:portal>
        <.modal id="user_modal" responsive backdrop={false}>
          <.simple_form
            :let={f}
            for={%{}}
            as={:user}
            phx-submit={JS.push("create") |> JS.dispatch("submit:close")}
          >
            <.fieldset
              legend={~t"Create new user"m}
              text={~t"This won't be persisted into DB, memory only"m}
            >
              <.fieldgroup>
                <div class="grid grid-cols-1 gap-8 sm:grid-cols-2 sm:gap-4">
                  <.field field={f[:first_name]} label={~t"First name"m} required />
                  <.field field={f[:last_name]} label={~t"Last name"m} required />
                </div>
                <div class="grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-4">
                  <div class="sm:col-span-2">
                    <.field field={f[:email]} label={~t"EMail"m} type="email" required />
                  </div>
                  <.field field={f[:age]} label={~t"Age"m} type="number" required />
                </div>
              </.fieldgroup>
            </.fieldset>
            <:actions>
              <button type="button" class="btn btn-ghost" onclick="user_modal.close()">
                <%= ~t"Cancel"m %>
              </button>
              <button type="reset" class="btn btn-ghost"><%= ~t"Reset"m %></button>
              <button type="submit" class="btn btn-neutral"><%= ~t"Save user"m %></button>
            </:actions>
          </.simple_form>
        </.modal>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("create", %{"user" => params}, socket) do
    user = %__MODULE__{
      first_name: params["first_name"],
      last_name: params["last_name"],
      email: params["email"],
      age: params["age"],
      id: socket.assigns.current_id + 1
    }

    {:noreply,
     socket
     |> put_flash(:info, ~t"User created successfully"m)
     |> update(:users, &(&1 ++ [user]))
     |> update(:current_id, &(&1 + 1))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, ~t"User deleted successfully"m)
     |> update(:users, &List.delete_at(&1, find_index(socket, id)))}
  end

  @impl true
  def handle_event("select_user", %{"id" => id}, socket) do
    socket =
      assign(socket, :selected_user, find_user(socket, id))

    {:noreply, socket}
  end

  def full_name(%__MODULE__{} = user) do
    "#{user.first_name} #{user.last_name}"
  end

  defp find_user(socket, id) do
    Enum.find(socket.assigns.users, &(&1.id == id))
  end

  def find_index(socket, id) do
    Enum.find_index(socket.assigns.users, &(&1.id == id))
  end

  defp seed_users do
    for i <- 1..20 do
      %__MODULE__{
        id: i,
        first_name: "John-#{i}",
        last_name: "Doe",
        email: "john-$#{i}.doe@example",
        age: 20 + i
      }
    end
  end
end
