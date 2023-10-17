defmodule DataAggregatorWeb.ImportRecordLive.FormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Imports.ImportRecord

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage import_record in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="import_record-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:unique_qualifier]} label="Unique Qualifier" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Import Record</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new}) do
    ImportRecord
    |> Form.for_create(:create, api: DataAggregator.Imports, as: "import_record")
    |> to_form()
  end

  defp build_form(%{action: :edit, import_record: import_record}) do
    import_record
    |> Form.for_update(:update, api: DataAggregator.Imports, as: "import_record")
    |> to_form()
  end

  @impl true
  @spec handle_event(
          <<_::32, _::_*32>>,
          map(),
          atom()
          | %{
              :assigns =>
                atom()
                | %{
                    :form => %{
                      :__struct__ => AshPhoenix.Form | Phoenix.HTML.Form,
                      :action => atom() | binary(),
                      :data => nil | map(),
                      :errors => boolean() | list(),
                      :id => any(),
                      :name => any(),
                      :params => map(),
                      :source => any(),
                      optional(:added?) => any(),
                      optional(:any_removed?) => any(),
                      optional(:api) => any(),
                      optional(:changed?) => any(),
                      optional(:form_keys) => list(),
                      optional(:forms) => map(),
                      optional(:hidden) => list(),
                      optional(:impl) => atom(),
                      optional(:index) => nil | non_neg_integer(),
                      optional(:just_submitted?) => boolean(),
                      optional(:method) => binary(),
                      optional(:options) => list(),
                      optional(:opts) => list(),
                      optional(:original_data) => any(),
                      optional(:prepare_params) => any(),
                      optional(:prepare_source) => nil | (any() -> any()),
                      optional(:resource) => atom(),
                      optional(:submit_errors) => nil | list(),
                      optional(:submitted_once?) => boolean(),
                      optional(:touched_forms) => any(),
                      optional(:transform_errors) => nil | (any(), any() -> any()),
                      optional(:transform_params) => nil | (any() -> any()),
                      optional(:type) => :create | :destroy | :read | :update,
                      optional(:valid?) => boolean(),
                      optional(:warn_on_unhandled_errors?) => any()
                    },
                    optional(any()) => any()
                  },
              optional(any()) => any()
            }
        ) :: {:noreply, any()}
  def handle_event("validate", %{"import_record" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"import_record" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, course} ->
          notify_parent({:saved, course})

          message =
            case socket.assigns.action do
              :new -> "Import Record created successfully"
              :edit -> "Import Record updated successfully"
            end

          socket
          |> push_patch(to: socket.assigns.patch)
          |> put_flash(:info, message)

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
