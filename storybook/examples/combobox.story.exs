defmodule Storybook.Examples.Combobox do
  @moduledoc false
  use PhoenixStorybook.Story, :example
  use DataAggregatorWeb.Components
  use DataAggregatorWeb.Blocks

  def doc do
    "An example of how to use comboboxes."
  end

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :assignee, :string
    end

    def changeset(%__MODULE__{} = form, params \\ %{}) do
      form
      |> cast(params, [:assignee])
      |> validate_required([:assignee])
    end
  end

  @options [
    %{value: "ft", label: "Fredrik Teschke"},
    %{value: "jd", label: "John Doe"},
    %{value: "ck1", label: "Clark Kent"},
    %{value: "ck2", label: "Clark Kent 2"},
    %{value: "ck3", label: "Clark Kent 3"},
    %{value: "ck4", label: "Clark Kent 4"},
    %{value: "ck5", label: "Clark Kent 5"},
    %{value: "ck6", label: "Clark Kent 6"},
    %{value: "ck7", label: "Clark Kent 7"},
    %{value: "ck8", label: "Clark Kent 8"},
    %{value: "ck9", label: "Clark Kent 9"},
    %{value: "ck10", label: "Clark Kent 10"},
    %{value: "ck11", label: "Clark Kent 11"},
    %{value: "ck12", label: "Clark Kent 12"},
    %{value: "ck13", label: "Clark Kent 13"},
    %{value: "ck14", label: "Clark Kent 14"},
    %{value: "ck15", label: "Clark Kent 15"},
    %{value: "ck16", label: "Clark Kent 16"},
    %{value: "ck17", label: "Clark Kent 17"},
    %{value: "ck18", label: "Clark Kent 18"},
    %{value: "ck19", label: "Clark Kent 19"}
  ]

  @options_with_groups %{
    "Group 1" => [
      %{value: "ft", label: "Fredrik Teschke"},
      %{value: "jd", label: "John Doe"}
    ],
    "Group 2" => [
      %{value: "ck1", label: "Clark Kent"},
      %{value: "ck2", label: "Clark Kent 2"},
      %{value: "ck3", label: "Clark Kent 3"},
      %{value: "ck4", label: "Clark Kent 4"},
      %{value: "ck5", label: "Clark Kent 5"},
      %{value: "ck6", label: "Clark Kent 6"},
      %{value: "ck7", label: "Clark Kent 7"},
      %{value: "ck8", label: "Clark Kent 8"},
      %{value: "ck9", label: "Clark Kent 9"},
      %{value: "ck10", label: "Clark Kent 10"},
      %{value: "ck11", label: "Clark Kent 11"},
      %{value: "ck12", label: "Clark Kent 12"},
      %{value: "ck13", label: "Clark Kent 13"},
      %{value: "ck14", label: "Clark Kent 14"},
      %{value: "ck15", label: "Clark Kent 15"},
      %{value: "ck16", label: "Clark Kent 16"},
      %{value: "ck17", label: "Clark Kent 17"},
      %{value: "ck18", label: "Clark Kent 18"},
      %{value: "ck19", label: "Clark Kent 19"}
    ]
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:options, @options)
     |> assign(:options_with_groups, @options_with_groups)
     |> assign(:selected, "jd")
     |> assign(:other_selected, "")
     |> assign(:changeset, Form.changeset(%Form{}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.page_header class="px-6 pb-4 pt-1 lg:px-8 md:py-6">Comboboxes</.page_header>

      <div class="max-w-sm space-y-8 px-6 lg:px-8">
        <div>
          <.section_heading text="Combobox simple" size="md" class="mb-2" />
          <x-combobox
            phx-hook="EventBridgeHook"
            phx-update="ignore"
            id="react-combobox"
            data-options={Jason.encode!(@options)}
            data-value={@selected}
            data-prompt="Select a name"
          />
        </div>
        <div>
          <.section_heading text="Combobox with groups" size="md" class="mb-2" />
          <x-combobox
            phx-hook="EventBridgeHook"
            phx-update="ignore"
            id="react-combobox-with-groups"
            data-options={Jason.encode!(@options_with_groups)}
            data-value={@selected}
            data-placeholder="Select a name"
          />
        </div>
        <div>
          <.section_heading text="Combobox with custom select event" size="md" class="mb-2" />
          <x-combobox
            phx-hook="EventBridgeHook"
            phx-update="ignore"
            id="react-combobox-with-custom-event"
            data-options={Jason.encode!(@options)}
            data-value={@selected}
            data-prompt="Select a name"
            data-event="user:select"
          />
        </div>
        <div>
          <.section_heading text="Combobox with initial empty selection" size="md" class="mb-2" />
          <x-combobox
            phx-hook="EventBridgeHook"
            phx-update="ignore"
            id="react-combobox-with-initial-empty-selection"
            data-options={Jason.encode!(@options)}
            data-value={@other_selected}
            data-prompt="Select a name"
            data-event="other:select"
          />
        </div>
        <div>
          <.section_heading text="Combobox with form" size="md" class="mb-2" />
          <.simple_form :let={form} for={@changeset} phx-change="validate" phx-submit="save">
            <.field
              field={form[:assignee]}
              type="combobox"
              id="react-combobox-with-form"
              prompt="Select a name"
              options={@options_with_groups}
            />
            <:actions>
              <button type="submit" class="btn btn-primary">Save</button>
            </:actions>
          </.simple_form>
        </div>
      </div>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  @impl true
  def handle_event("select", %{"value" => value}, socket) do
    {:noreply, assign(socket, :selected, value)}
  end

  @impl true
  def handle_event("user:select", %{"value" => value}, socket) do
    {:noreply, assign(socket, :selected, value)}
  end

  @impl true
  def handle_event("other:select", %{"value" => value}, socket) do
    {:noreply, assign(socket, :other_selected, value)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    {:noreply, assign(socket, :changeset, Form.changeset(%Form{}, params))}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    result =
      %Form{}
      |> Form.changeset(params)
      |> Ecto.Changeset.apply_action(:create)

    case result do
      {:ok, data} -> {:noreply, put_flash(socket, :info, "Saved #{inspect(data)}!")}
      {:error, changeset} -> {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
