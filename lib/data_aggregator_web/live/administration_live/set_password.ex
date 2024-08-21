defmodule DataAggregatorWeb.AdministrationLive.SetPassword do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  alias AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign_form(socket)}
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{current_user: user}) do
    user
    |> Form.for_update(:set_password, api: DataAggregator.Accounts, as: "user")
    |> to_form()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-full flex-1 flex-col justify-center px-6 py-12 lg:px-8">
      <.simple_form
        for={@form}
        id="set-password-form"
        phx-submit="user:save"
        phx-change="user:validate"
        class="mt-10 sm:mx-auto sm:w-full sm:max-w-sm"
      >
        <div class="h-full overflow-y-auto px-6 py-8">
          <.fieldgroup>
            <.field
              type="password"
              field={@form[:password]}
              label={~t"Password"m}
              placeholder={~t"Enter your password"m}
            />
            <div>
              <button
                type="submit"
                class="flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <%= ~t"Set Password"m %>
              </button>
            </div>
          </.fieldgroup>
        </div>
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
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, _user} ->
          push_navigate(socket, to: build_path(~p"/", nil))

        {:error, form} ->
          socket
          |> put_flash(:error, ~t"Something went wrong"m)
          |> assign(:form, form)
      end

    {:noreply, socket}
  end
end
