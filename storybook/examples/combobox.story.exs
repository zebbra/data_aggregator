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
      field :users, {:array, :string}
    end

    def changeset(%__MODULE__{} = form, params \\ %{}) do
      form
      |> cast(params, [:assignee])
      |> cast(params, [:users])
      |> validate_required([:assignee])
      |> validate_required([:users])
    end
  end

  @options [
    [key: "I am a disabled option", value: "ck2", disabled: true],
    [key: "With key value", value: "ck20"],
    "Fredrik Teschke": "ft",
    "John Doe": "jd",
    "Clark Kent": "ck1",
    "Clark Kent 3": "ck3",
    "Clark Kent 4": "ck4",
    "Clark Kent 5": "ck5",
    "Clark Kent 6": "ck6",
    "Clark Kent 7": "ck7",
    "Clark Kent 8": "ck8",
    "Clark Kent 9": "ck9",
    "Clark Kent 10": "ck10",
    "Clark Kent 11": "ck11",
    "Clark Kent 12": "ck12",
    "Clark Kent 13": "ck13",
    "Clark Kent 14": "ck14",
    "Clark Kent 15": "ck15",
    "Clark Kent 16": "ck16",
    "Clark Kent 17": "ck17",
    "Clark Kent 18": "ck18",
    "Clark Kent 19": "ck19"
  ]

  @search_options [
    "Fredrik Teschke": "ft",
    "John Doe": "jd",
    "Clark Kent": "ck1",
    "Clark Kent 3": "ck3",
    "Clark Kent 4": "ck4",
    "Clark Kent 5": "ck5",
    "Clark Kent 6": "ck6",
    "Clark Kent 7": "ck7",
    "Clark Kent 8": "ck8",
    "Clark Kent 9": "ck9"
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:selected, "ck1")
     |> assign(:users, [])
     |> assign(options: @options)
     |> assign(search_options: @search_options)
     |> assign(:changeset, Form.changeset(%Form{}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.page_header title_class="px-6 lg:px-8 md:py-6">
        Comboboxes
      </.page_header>
      <div class="max-w-lg space-y-8 px-6 pb-20 lg:px-8">
        <div>
          <.section_heading text="Single select" size="md" class="mb-2" />
          <.combobox id="single" options={@options} />
        </div>
        <div>
          <.section_heading text="Multiple select" size="md" class="mb-2" />
          <.combobox
            id="multiple"
            options={@options}
            multiple
            value={[
              "Clark Kent 15",
              "ck15",
              "Clark Kent 16",
              "ck16",
              "Clark Kent 17",
              "ck17"
            ]}
          />
        </div>
        <div>
          <.section_heading text="Single select with counter badge" size="md" class="mb-2" />
          <.combobox
            id="single_counter_badge"
            options={[
              [key: "Clark Kent 1", value: "ck1", count: 2],
              [key: "Clark Kent 2", value: "ck2", count: 5],
              [key: "Clark Kent 3", value: "ck3", count: 0, disabled: true]
            ]}
            tom_select_plugins={%{counter_badge: %{}}}
          />
        </div>
        <div>
          <.section_heading text="Multiple select with counter badge" size="md" class="mb-2" />
          <.combobox
            id="multiple_counter_badge"
            options={[
              [key: "Clark Kent 1", value: "ck1", count: 2],
              [key: "Clark Kent 2", value: "ck2", count: 5],
              [key: "Clark Kent 3", value: "ck3", count: 0, disabled: true]
            ]}
            multiple
            tom_select_plugins={%{counter_badge: %{}}}
          />
        </div>
        <div>
          <.section_heading text="Single select event based" size="md" class="mb-2" />
          <.combobox id="single_event" options={@options} value={@selected} on-change />
          <div class="text-base-content/60 mt-1">Selected: <%= @selected %></div>
        </div>
        <div>
          <.section_heading text="Multiple select event based" size="md" class="mb-2" />
          <.combobox
            id="multi_event"
            options={@options}
            value={@users}
            on-change="select:users"
            multiple
          />
          <div class="text-base-content/60 mt-1">Selected: <%= inspect(@users) %></div>
        </div>
        <div>
          <.section_heading text="Remote option search single" size="md" class="mb-2" />
          <.combobox
            id="remote_search_single"
            remote_options_event_name="search"
            placeholder="Search for a user.."
          />
        </div>
        <div>
          <.section_heading text="Remote option search multiple" size="md" class="mb-2" />
          <.combobox
            id="remote_search_multiple"
            remote_options_event_name="search"
            placeholder="Search for users.."
            multiple
          />
        </div>
        <div>
          <.section_heading text="Create new option" size="md" class="mb-2" />
          <.combobox id="create" options={@options} create />
        </div>
        <div>
          <.section_heading text="Disabled" size="md" class="mb-2" />
          <.combobox id="disabled" options={@options} disabled />
        </div>
        <div>
          <.section_heading text="Disabled multiple" size="md" class="mb-2" />
          <.combobox
            id="disabled_multiple"
            options={@options}
            value={["Clark Kent 16", "ck16", "Clark Kent 17", "ck17"]}
            multiple
            disabled
          />
        </div>
        <div>
          <.section_heading text="Max items" size="md" class="mb-2" />
          <.combobox id="max_items" options={@options} max_items={2} />
        </div>
        <div>
          <.section_heading text="Placeholder" size="md" class="mb-2" />
          <.combobox id="placeholder" options={@options} placeholder="Select an option..." />
        </div>
        <div>
          <.section_heading text="Placeholder multiple" size="md" class="mb-2" />
          <.combobox
            id="placeholder_multiple"
            options={@options}
            placeholder="Select an option..."
            multiple
          />
        </div>
        <div>
          <.section_heading text="Prompt" size="md" class="mb-2" />
          <.combobox id="prompt" options={@options} prompt="Select an option..." />
        </div>
        <div>
          <.section_heading text="Prompt multiple" size="md" class="mb-2" />
          <.combobox id="prompt_multiple" options={@options} prompt="Select an option..." multiple />
        </div>
        <div>
          <.section_heading text="Option groups" size="md" class="mb-2" />
          <.combobox
            id="option_groups"
            options={[Birds: ["Eagle", "Seagull"], Animals: ["Dog", "Rhino"]]}
          />
        </div>
        <div>
          <.section_heading text="Combobox with form" size="md" class="mb-2" />
          <.simple_form :let={form} for={@changeset} phx-change="validate" phx-submit="save">
            <.fieldset>
              <.fieldgroup>
                <.field
                  field={form[:assignee]}
                  type="combobox"
                  id="combobox_with_form"
                  label="Assignee"
                  prompt="Select a name"
                  options={[Birds: ["Eagle", "Seagull"], Animals: ["Dog", "Rhino"]]}
                />
                <.field
                  field={form[:users]}
                  type="combobox"
                  id="combobox_with_form_with_multiple"
                  label="Users"
                  prompt="Select some users"
                  options={@options}
                  multiple
                />
              </.fieldgroup>
            </.fieldset>
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
  def handle_event("search", payload, socket) do
    results =
      @search_options
      |> Enum.filter(fn {full_name, _} ->
        String.contains?(String.downcase(Atom.to_string(full_name)), String.downcase(payload))
      end)
      |> Enum.map(fn {full_name, username} ->
        %{text: full_name, value: username}
      end)

    {:reply, %{results: results}, socket}
  end

  @impl true
  def handle_event("change", %{"value" => value}, socket) do
    {:noreply, assign(socket, :selected, value)}
  end

  @impl true
  def handle_event("select:users", %{"value" => value}, socket) do
    {:noreply, assign(socket, :users, value)}
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
