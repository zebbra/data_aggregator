defmodule DataAggregatorWeb.AdministrationLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.AdministrationLive.Subscriptions

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif

  @dialyzer {:no_return, render: 1}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(selected_user: nil)
      |> assign(selected_user_institution: nil)

    {:ok, subscribe_for_administration_updates(socket, connected?(socket))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_users(params, get_actor(socket)) do
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
      <.page_header class="px-6 pt-1 pb-4 md:py-6 lg:px-8">
        {~t"Administration"m}
        <:actions>
          <.link patch={~p"/administration/new"} class="btn btn-primary max-sm:btn-sm">
            <.icon name="hero-user-plus" class="max-sm:size-4" />
            <span class="max-sm:hidden">{~t"Add User"m}</span>
            <span class="sm:hidden">{~t"Add"m}</span>
          </.link>
        </:actions>
      </.page_header>
      <.table
        opts={[
          container_attrs: [
            class: "overflow-x-auto pb-4"
          ],
          no_results_content: no_results_content()
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
        <:col :let={{_id, user}} field={:email} label={~t"Email"m}>
          {user.email}
        </:col>
        <:col :let={{_id, user}} field={:first_name} label={~t"First Name"m}>
          {user.first_name}
        </:col>
        <:col :let={{_id, user}} field={:last_name} label={~t"Last Name"m}>
          {user.last_name}
        </:col>
        <:col :let={{_id, user}} field={:phone} label={~t"Phone"m}>
          {user.phone}
        </:col>
        <:col :let={{_id, user}} field={:roles} label={~t"Roles"m}>
          <%= for role <- user.roles do %>
            <.badge color="gray" class="mt-0.5">
              <span class="px-1.5">{role}</span>
            </.badge>
          <% end %>
        </:col>
        <:col :let={{_id, user}} label={~t"Institution"m}>
          <%= if user.institution_id do %>
            {get_institution_name(user.institution_id)}
          <% end %>
        </:col>
        <:action
          :let={{_id, user}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <div class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.table_action_button
              patch={build_path(~p"/administration/#{user}/edit", @meta)}
              data-tip={~t"Edit"m}
              icon="hero-pencil-square-mini"
            />
          </div>
          <.table_action_button
            phx-click={JS.push("user:delete", value: %{id: user.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_administration_alert"
            disabled={User.can_destroy?(@current_user, user) == false}
            icon="hero-trash-mini"
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
          <.list :if={@selected_user}>
            <:item title={~t"E-Mail"m}>
              {@selected_user.email}
            </:item>
            <:item title={~t"Institution"m}>
              {@selected_user_institution["name"]}
            </:item>
            <:item title={~t"Address"m}>
              <p>
                {@selected_user_institution["address"]["address"]}
              </p>
              <p>
                {@selected_user_institution["address"]["postalCode"]}
              </p>
              <p>
                {@selected_user_institution["address"]["city"]}
              </p>
            </:item>
            <:item title={~t"Roles"m}>
              <%= for role <- @selected_user.roles do %>
                <.badge color="gray" class="mt-0.5">
                  <span class="px-1.5">{role}</span>
                </.badge>
              <% end %>
            </:item>
          </.list>
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
        <.alert
          id="confirm_administration_alert"
          size="sm"
          title={~t"Are you sure?"m}
          confirm_button_label={~t"Yes, delete user"m}
        />
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
    user = get_user(id, get_actor(socket))

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:selected_user_institution, get_institution(user))}
  end

  @impl true
  def handle_event("user:delete", %{"id" => id}, socket) do
    user = User.get_by_id!(id, actor: get_actor(socket))
    :ok = User.destroy(user, actor: get_actor(socket))

    {:noreply,
     socket
     |> put_flash(:info, ~t"User deleted successfully"m)
     |> stream_delete(:results, user)}
  end

  defp user_name(nil), do: ""
  defp user_name(user), do: "#{user.first_name} #{user.last_name}"

  defp get_user(id, actor) do
    User.get_by_id!(id, actor: actor)
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
    |> assign(:user, get_user(id, get_actor(socket)))
  end

  defp list_users(params, actor, opts \\ []) do
    opts = Keyword.put(opts, :actor, actor)
    AshPagify.validate_and_run(User, params, opts)
  end

  def no_results_content(assigns \\ %{}) do
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
