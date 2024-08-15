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
     |> assign_institution_options()}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_form()}
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
                  type="password"
                  field={@form[:password]}
                  label={~t"Password"m}
                  placeholder={~t"Enter password"m}
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

              <div class="grid grid-cols-1 gap-8">
                <.field
                  type="checkbox"
                  field={@form[:send_password_by_mail]}
                  label={~t"Send password to user by e-mail"m}
                />
                <.field
                  type="checkbox"
                  field={@form[:password_reset_required]}
                  label={~t"User has to change password upon login"m}
                />
              </div>
            </.fieldgroup>
          </.fieldset>
          <%!-- roles --%>
          <.fieldset class={unless @step == :role, do: "hidden"}>
            <.fieldgroup>
              <div class="grid grid-cols-1 gap-8">
                <%!-- <.field
                  field={@form[:roles]}
                  required
                  id="field-basic-inputs-toggle"
                  label="Toggle input"
                  type="toggle"
                  description="Toggle input description"
                  autocomplete="toggle"
                /> --%>
                <.field
                  field={@form[:roles]}
                  id="roles_checkgroup"
                  label="Checkgroup"
                  type="togglegroup"
                  options={[
                    "Collection Digitizer": "collection_digitizer",
                    "Data Administrator": "data_administrator"
                  ]}
                  description="Checkgroup input description"
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
                  type="password"
                  field={@form[:password]}
                  label={~t"Password"m}
                  placeholder={~t"Enter password"m}
                  disabled={true}
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
          socket
          |> put_flash(:info, ~t"An error occurred"m)
          |> assign(:form, form)
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

  defp generate_password(length) do
    length |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, length)
  end

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
    |> Form.for_create(:register_with_password, api: DataAggregator.Accounts, as: "user")
    |> to_form()
  end

  defp build_form(%{action: :edit, user: user}) do
    user
    |> Form.for_update(:update, api: DataAggregator.Accounts, as: "user")
    |> to_form()
  end

  defp assign_institution_options(socket) do
    assign(socket, :grscicoll_institutions, Gbif.RestAPI.get_institution_options())
  end
end
