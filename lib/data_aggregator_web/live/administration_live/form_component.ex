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
        <.stepper current={current_step(@step)} steps={3} />
        <.section_heading text={heading(@step)} class="mt-4" />
      </.modal_header>

      <.simple_form
        for={@form}
        id="user_form"
        phx-submit="user:save"
        phx-target={@myself}
        phx-change="user:validate"
      >
        <div class="h-full overflow-y-auto px-6 py-8">
          <%!-- user data --%>
          <.fieldset class={unless @step == :user, do: "hidden"}>
            <.fieldgroup>
              <div class="grid grid-cols-2 gap-8">
                <.field
                  type="text"
                  field={@form[:first_name]}
                  label={~t"First name"m}
                  placeholder={~t"Enter first name"m}
                />
                <.field
                  type="text"
                  field={@form[:last_name]}
                  label={~t"Last name"m}
                  placeholder={~t"Enter last name"m}
                />
                <.field
                  type="text"
                  field={@form[:email]}
                  label={~t"E-Mail"m}
                  placeholder={~t"Enter E-Mail"m}
                />
                <.field
                  type="text"
                  field={@form[:phone]}
                  label={~t"Phone"m}
                  placeholder={~t"Enter phone number"m}
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
                />
                <button
                  type="button"
                  phx-click="user:generate_password"
                  phx-target={@myself}
                  class="btn btn-outline border-base-content/20 mt-8 max-sm:btn-sm"
                >
                  <%= ~t"Generate Password"m %>
                </button>
              </div>
            </.fieldgroup>
          </.fieldset>
          <%!-- roles --%>
          <.fieldset class={unless @step == :role, do: "hidden"}>
            <.fieldgroup>
              <div class="grid grid-cols-1 gap-8">
                <.field
                  field={@form[:roles]}
                  id="roles_togglegroup"
                  label="togglegroup"
                  type="togglegroup"
                  options={[
                    "Collection Digitizer": "collection_digitizer",
                    "Data Administrator": "data_administrator"
                  ]}
                  description="togglegroup input description"
                  multiple
                />
              </div>
            </.fieldgroup>
          </.fieldset>
          <%!-- summary --%>
          <.fieldset class={unless @step == :summary, do: "hidden"}>
            <.fieldgroup>
              <div class="grid grid-cols-2 gap-8">
                <.field
                  id="first_name_summary"
                  type="text"
                  field={@form[:first_name]}
                  label={~t"First name"m}
                  disabled={true}
                  placeholder={~t"Enter first name"m}
                />
                <.field
                  id="last_name_summary"
                  type="text"
                  field={@form[:last_name]}
                  label={~t"Last name"m}
                  disabled={true}
                  placeholder={~t"Enter last name"m}
                />
                <.field
                  id="email_summary"
                  type="text"
                  field={@form[:email]}
                  label={~t"E-Mail"m}
                  disabled={true}
                  placeholder={~t"Enter E-Mail"m}
                />
                <.field
                  id="phone_summary"
                  type="text"
                  field={@form[:phone]}
                  label={~t"Phone"m}
                  disabled={true}
                  placeholder="-"
                />
              </div>
              <div class="grid grid-cols-1">
                <.field
                  type="combobox"
                  id="combobox_summary"
                  name="combobox_summary"
                  field={@form[:institution_id]}
                  label={~t"Institution"m}
                  options={@grscicoll_institutions}
                  disabled={true}
                  placeholder={~t"Select institutions"m}
                />
              </div>
              <div class="grid grid-cols-2 gap-8">
                <.field
                  id="password_summary"
                  type={password_type(@password_hidden?)}
                  field={@form[:password]}
                  label={~t"Password"m}
                  placeholder={~t"Enter password"m}
                  disabled={true}
                  icon_end={password_icon(@password_hidden?)}
                  icon_event="toggle_password"
                  icon_event_target={@myself}
                />
              </div>
            </.fieldgroup>
            <.fieldgroup>
              <%!-- <.label label={~t"Roles"m} for="testy" /> --%>
              <div class="grid grid-cols-1 gap-8">
                <.field
                  field={@form[:roles]}
                  id="roles_summary"
                  name="roles_summary"
                  disabled={true}
                  label="Roles"
                  type="togglegroup"
                  options={[
                    "Collection Digitizer": "collection_digitizer",
                    "Data Administrator": "data_administrator"
                  ]}
                  multiple
                />
              </div>
            </.fieldgroup>
          </.fieldset>
        </div>

        <:actions modal>
          <button
            :if={@step != :summary}
            class="btn btn-primary"
            type="button"
            phx-click="user:next"
            phx-target={@myself}
          >
            <%= ~t"Next"m %>
          </button>
          <button :if={@step == :summary} class="btn btn-primary" type="submit">
            <%= ~t"Save"m %>
          </button>
          <button
            :if={@step == :user}
            class="btn btn-ghost"
            type="button"
            onclick="user_modal.close()"
            phx-target={@myself}
          >
            <%= ~t"Cancel"m %>
          </button>
          <button
            :if={@step != :user}
            class="btn btn-ghost"
            type="button"
            phx-click="user:back"
            phx-target={@myself}
          >
            <%= ~t"Back"m %>
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("user:validate", %{"user" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("user:save", %{"user" => params}, socket) do
    # TODO: This is a workaround to remove empty values from the roles list
    # why is this necessary?
    roles = params["roles"] || []
    # This line removes empty values
    roles = Enum.reject(roles, &(&1 == ""))
    params = Map.put(params, "roles", roles)

    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, _user} ->
          socket
          |> push_event("submit:close", %{})
          |> push_patch(to: build_path(~p"/administration", nil))

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("user:next", _, %{assigns: %{step: :user}} = socket) do
    # form = socket.assigns.form

    # case Form.validate(form, form.params) do
    #   %{errors: []} -> assign(socket, step: :role)
    #   %{errors: _errors} -> assign(socket, form: form)
    # end
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

  defp build_form(%{action: :new}) do
    User
    |> Form.for_create(:register_with_password, domain: DataAggregator.Accounts, as: "user")
    |> to_form()
  end

  defp build_form(%{action: :edit, user: user}) do
    user
    |> Form.for_update(:update, domain: DataAggregator.Accounts, as: "user")
    |> to_form()
  end

  defp assign_institution_options(socket) do
    options =
      if "admin" in socket.assigns.current_user.roles do
        Gbif.RestAPI.get_institution_options()
      else
        [Gbif.RestAPI.get_institution_option(socket.assigns.current_user.institution_id)]
      end

    assign(socket, :grscicoll_institutions, options)
  end
end
