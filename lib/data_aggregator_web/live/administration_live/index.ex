defmodule DataAggregatorWeb.AdministrationLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(selected_user: nil)
     |> assign(selected_user_institution: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_users(params, socket.assigns.current_user) do
      {:ok, {users, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, users, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/administration")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="administration" current_user={@current_user} open={@selected_user != nil}>
      <.page_header class="px-6 pb-4 pt-1 lg:px-8 md:py-6">
        <%= ~t"Administration"m %>
        <:actions>
          <.link patch={~p"/administration/new"} class="btn btn-primary max-sm:btn-sm">
            <.icon name="hero-squares-2x2" class="max-sm:size-4" />
            <span class="max-sm:hidden"><%= ~t"Add User"m %></span>
            <span class="sm:hidden"><%= ~t"Add"m %></span>
          </.link>
        </:actions>
      </.page_header>
      <.table
        opts={[
          container_attrs: [
            class: "no-scrollbar overflow-x-auto pb-4"
          ],
          no_results_content: no_results_content(%{current_user: @current_user})
        ]}
        path={~p"/administration"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, user} ->
            JS.push("user:select", value: %{id: user.id})
          end
        }
      >
        <:col :let={{_id, user}} field={:first_name} label={~t"First Name"m}>
          <%= user.first_name %>
        </:col>
        <:col :let={{_id, user}} field={:last_name} label={~t"Last Name"m}>
          <%= user.last_name %>
        </:col>
        <:col :let={{_id, user}} field={:email} label={~t"Email"m}>
          <%= user.email %>
        </:col>
        <:col :let={{_id, user}} field={:phone} label={~t"Phone"m}>
          <%= user.phone %>
        </:col>
        <:col :let={{_id, user}} label={~t"Roles"m}>
          <%= for role <- user.roles do %>
            <.badge color="gray">
              <span class="px-1.5"><%= role %></span>
            </.badge>
          <% end %>
        </:col>
        <:col :let={{_id, user}} field={:institution_id} label={~t"Institution"m}>
          <%= if user.institution_id do %>
            <%= get_institution_name(user.institution_id) %>
          <% end %>
        </:col>
        <:action
          :let={{_id, user}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <.table_action_button
            patch={build_path(~p"/administration/#{user}/edit", @meta)}
            data-tip={~t"Edit"m}
            icon="hero-pencil-square-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/administration"} />
      <:secondary>
        <.slideover
          title={user_name(@selected_user)}
          open={@selected_user != nil}
          on_cancel={JS.push("user:select", value: %{id: nil})}
          size="xl"
        >
          <div class="pl-8">
            <%!-- account --%>
            <dl class="pb-8">
              <div class="py-1 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-base-content/90 text-sm/6 font-medium">
                  <%= ~t"E-Mail"m %>
                </dt>
                <dd class="text-base-content/60 text-sm/6 mt-1 sm:col-span-2 sm:mt-0">
                  <%= @selected_user != nil && @selected_user.email %>
                </dd>
              </div>
              <div class="py-1 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-base-content/90 text-sm/6 font-medium">
                  <%= ~t"Last Login"m %>
                </dt>
                <dd class="text-base-content/60 text-sm/6 mt-1 sm:col-span-2 sm:mt-0">
                  <%= "13.11.1992" %>
                </dd>
              </div>
            </dl>
            <%!-- institution --%>
            <dl class="pb-8">
              <div class="py-1 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-base-content/90 text-sm/6 font-medium">
                  <%= ~t"Institution"m %>
                </dt>
                <dd class="text-base-content/60 text-sm/6 mt-1 sm:col-span-2 sm:mt-0">
                  <%= @selected_user_institution["name"] %>
                </dd>
              </div>
              <div class="py-1 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-base-content/90 text-sm/6 font-medium">
                  <%= ~t"Address"m %>
                </dt>
                <dd class="text-base-content/60 text-sm/6 mt-1 sm:col-span-2 sm:mt-0">
                  <p>
                    <%= @selected_user_institution["address"]["address"] %>
                  </p>
                  <p>
                    <%= @selected_user_institution["address"]["postalCode"] %>
                  </p>
                  <p>
                    <%= @selected_user_institution["address"]["city"] %>
                  </p>
                </dd>
              </div>
            </dl>
            <%!-- Roles --%>
            <dl class="pb-8">
              <div class="py-1 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-base-content/90 text-sm/6 font-medium">
                  <%= ~t"Roles"m %>
                </dt>
                <dd class="text-base-content/60 text-sm/6 mt-1 sm:col-span-2 sm:mt-0">
                  <%= for role <- @selected_user.roles do %>
                    <.badge color="gray">
                      <span class="px-1.5"><%= role %></span>
                    </.badge>
                  <% end %>
                </dd>
              </div>
            </dl>
          </div>
        </.slideover>
      </:secondary>
      <:portal>
        <.modal
          id="user_modal"
          show={@live_action in [:new, :edit]}
          size="2xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(build_path(~p"/administration", @meta))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :edit]}
            module={DataAggregatorWeb.AdministrationLive.FormComponent}
            id={@user.id || :new}
            action={@live_action}
            user={@user}
            current_user={@current_user}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("user:select", %{"id" => nil}, socket) do
    {:noreply,
     socket
     |> assign(:selected_user, nil)
     |> assign(:selected_user_institution, nil)}
  end

  @impl true
  def handle_event("user:select", %{"id" => id}, socket) do
    user = get_user(id)

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:selected_user_institution, get_institution(user))}
  end

  defp user_name(nil), do: ""
  defp user_name(user), do: "#{user.first_name} #{user.last_name}"

  defp get_user(id) do
    User.get_by_id!(id)
  end

  defp get_institution(%{institution_id: id}) do
    case Gbif.RestAPI.get_grscicoll_entity(id, :institution) do
      {:ok, institution} ->
        institution

      _ ->
        nil
    end
  end

  defp get_institution_name(reference) do
    case Gbif.RestAPI.get_grscicoll_entity(reference, :institution) do
      {:ok, %{"name" => result}} ->
        result

      _ ->
        nil
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Administration"m)
    |> assign(:user, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New User"m)
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :edit, %{"user_id" => id}) do
    socket
    |> assign(:page_title, ~t"Edit User"m)
    |> assign(:user, User.get_by_id!(id))
  end

  defp list_users(params, actor, opts \\ []) do
    opts = Keyword.merge(opts, authorize?: true, actor: actor)
    Pagify.validate_and_run(User, params, opts)
  end

  def no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No Users"m}
      description={~t"Get started by adding a new User."m}
      label={~t"New User"m}
      icon="hero-squares-2x2"
      href={~p"/administration/new"}
    />
    """
  end
end
