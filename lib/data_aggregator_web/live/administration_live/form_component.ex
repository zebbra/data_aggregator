defmodule DataAggregatorWeb.AdministrationLive.FormComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]

  alias AshPhoenix.Form
  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(step: :user)
     |> assign(password_hidden?: true)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_institution_options()
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id}>
        <.stepper current={current_step(@step)} steps={3} class="pr-2" />
        <.section_heading text={heading(@step)} class="mt-4" />
      </.modal_header>

      <.simple_form
        for={@form}
        id="user_form"
        phx-submit="user:save"
        phx-target={@myself}
        phx-change="user:validate"
        modal
      >
        <%!-- user data --%>
        <.fieldset :if={@step != :summary} id="user" class={unless @step == :user, do: "hidden"} modal>
          <.fieldgroup modal>
            <div class="grid grid-cols-2 gap-8">
              <.field
                field={@form[:first_name]}
                label={~t"First name"m}
                placeholder={~t"Enter first name"m}
                autocomplete="given-name"
              />
              <.field
                field={@form[:last_name]}
                label={~t"Last name"m}
                placeholder={~t"Enter last name"m}
                autocomplete="family-name"
              />
              <.field
                type="email"
                field={@form[:email]}
                label={~t"E-Mail"m}
                placeholder={~t"Enter E-Mail"m}
                autocomplete="email"
                required
              />
              <.field
                type="tel"
                field={@form[:phone]}
                label={~t"Phone"m}
                placeholder={~t"Enter phone number"m}
                autocomplete="tel"
              />
            </div>
            <div class="grid grid-cols-1">
              <.field
                type="combobox"
                field={@form[:institution_id]}
                label={~t"Institution"m}
                options={@grscicoll_institutions}
                placeholder={~t"Select institutions"m}
              />
            </div>

            <div class="grid grid-cols-2 gap-8">
              <.field
                type={password_type(@password_hidden?)}
                field={@form[:password]}
                label={~t"Password"m}
                placeholder={~t"Enter password"m}
                icon_end={password_icon(@password_hidden?)}
                icon_event="toggle_password"
                icon_event_target={@myself}
                autocomplete="current-password"
                required
              />
              <button
                type="button"
                phx-click="user:generate_password"
                phx-target={@myself}
                class="btn btn-outline border-base-content/20 mt-8"
              >
                <%= ~t"Generate Password"m %>
              </button>
            </div>
          </.fieldgroup>
          <:actions modal>
            <button class="btn btn-primary" type="button" phx-click="user:next" phx-target={@myself}>
              <%= ~t"Next"m %>
            </button>
            <button
              class="btn btn-ghost"
              type="button"
              onclick="user_modal.close()"
              phx-target={@myself}
            >
              <%= ~t"Cancel"m %>
            </button>
          </:actions>
        </.fieldset>
        <%!-- roles --%>
        <.fieldset
          :if={@step != :summary}
          id="roles"
          class={unless @step == :role, do: "hidden"}
          modal
        >
          <.fieldgroup modal>
            <div class="grid grid-cols-1 gap-8">
              <.toggle_group field={@form[:roles]} options={toggle_group_options()} multiple />
            </div>
          </.fieldgroup>
          <:actions modal>
            <button class="btn btn-primary" type="button" phx-click="user:next" phx-target={@myself}>
              <%= ~t"Next"m %>
            </button>
            <button class="btn btn-ghost" type="button" phx-click="user:back" phx-target={@myself}>
              <%= ~t"Back"m %>
            </button>
          </:actions>
        </.fieldset>
        <%!-- summary --%>
        <.fieldset :if={@step == :summary} id="summary" modal>
          <.fieldgroup modal>
            <div class="grid grid-cols-2 gap-8">
              <.field
                field={@form[:first_name]}
                label={~t"First name"m}
                placeholder={~t"Enter first name"m}
                readonly
              />
              <.field
                field={@form[:last_name]}
                label={~t"Last name"m}
                placeholder={~t"Enter last name"m}
                readonly
              />
              <.field
                type="email"
                field={@form[:email]}
                label={~t"E-Mail"m}
                placeholder={~t"Enter E-Mail"m}
                readonly
                required
              />
              <.field
                id="phone_summary"
                type="tel"
                field={@form[:phone]}
                label={~t"Phone"m}
                placeholder="-"
                readonly
              />
            </div>
            <div class="grid grid-cols-1">
              <.field
                type="select"
                field={@form[:institution_id]}
                options={@grscicoll_institutions}
                label={~t"Institution"m}
                class="pointer-events-none"
              />
            </div>
            <div class="grid gap-8 sm:grid-cols-2">
              <.field
                type={password_type(@password_hidden?)}
                field={@form[:password]}
                label={~t"Password"m}
                placeholder={~t"Enter password"m}
                icon_end={password_icon(@password_hidden?)}
                icon_event="toggle_password"
                icon_event_target={@myself}
                readonly
                required
              />
            </div>
            <div class="grid grid-cols-1 gap-8">
              <.toggle_group
                field={@form[:roles]}
                label="Roles"
                options={toggle_group_options()}
                multiple
                class="pointer-events-none"
              />
            </div>
          </.fieldgroup>
          <:actions modal>
            <button class="btn btn-primary" type="submit">
              <%= if @action == :new, do: ~t"Create user"m, else: ~t"Update user"m %>
            </button>
            <button class="btn btn-ghost" type="button" phx-click="user:back" phx-target={@myself}>
              <%= ~t"Back"m %>
            </button>
          </:actions>
        </.fieldset>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("user:validate", %{"user" => params}, socket) do
    roles = params["roles"] || []
    roles = Enum.reject(roles, &(&1 == ""))
    params = Map.put(params, "roles", roles)

    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("user:save", %{"user" => params}, socket) do
    roles = params["roles"] || []
    roles = Enum.reject(roles, &(&1 == ""))
    params = Map.put(params, "roles", roles)

    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, _user} ->
          message =
            if socket.assigns.action == :new,
              do: ~t"User created successfully"m,
              else: ~t"User updated successfully"m

          socket
          |> push_event("submit:close", %{})
          |> push_patch(to: build_path(~p"/administration", nil))
          |> put_flash(:info, message)

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("user:next", _, %{assigns: %{step: :user}} = socket) do
    {:noreply, assign(socket, step: :role)}
  end

  @impl true
  def handle_event("user:generate_password", _, %{assigns: %{form: form}} = socket) do
    params = Map.put(form.params, "password", generate_password(12))
    socket = assign(socket, :form, Form.validate(form, params))

    {:noreply, socket}
  end

  @impl true
  def handle_event("user:next", _, %{assigns: %{step: :role}} = socket) do
    {:noreply, assign(socket, step: :summary)}
  end

  @impl true
  def handle_event("user:back", _, %{assigns: %{step: :summary}} = socket) do
    {:noreply, assign(socket, step: :role)}
  end

  @impl true
  def handle_event("user:back", _, %{assigns: %{step: :role}} = socket) do
    {:noreply, assign(socket, step: :user)}
  end

  @impl true
  def handle_event("toggle_password", _, socket) do
    {:noreply, assign(socket, :password_hidden?, not socket.assigns.password_hidden?)}
  end

  defp generate_password(length) do
    length |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, length)
  end

  defp password_type(true), do: "password"
  defp password_type(false), do: "text"

  defp password_icon(true), do: "hero-eye"
  defp password_icon(false), do: "hero-eye-slash"

  defp current_step(:user), do: 1
  defp current_step(:role), do: 2
  defp current_step(:summary), do: 3

  defp heading(:user), do: ~t"Add User"m
  defp heading(:role), do: ~t"Add Role"m
  defp heading(:summary), do: ~t"Summary"m

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new, current_user: current_user}) do
    User
    |> Form.for_create(:register_with_password,
      domain: DataAggregator.Accounts,
      as: "user",
      actor: current_user
    )
    |> to_form()
  end

  defp build_form(%{action: :edit, user: user, current_user: current_user}) do
    user
    |> Form.for_update(:update, domain: DataAggregator.Accounts, as: "user", actor: current_user)
    |> to_form()
  end

  defp assign_institution_options(socket) do
    options =
      if "admin" in get_actor(socket).roles do
        Gbif.RestAPI.get_institution_options()
      else
        [Gbif.RestAPI.get_institution_option(get_actor(socket).institution_id)]
      end

    assign(socket, :grscicoll_institutions, options)
  end

  defp toggle_group_options do
    [
      "Collection Digitizer": "collection_digitizer",
      "Data Administrator": "data_administrator",
      Admin: "admin"
    ]
  end
end
