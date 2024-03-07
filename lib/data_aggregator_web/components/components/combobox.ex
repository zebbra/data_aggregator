defmodule DataAggregatorWeb.Components.Combobox do
  @moduledoc """
  Combobox components.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext

  @doc """
  A combobox is a select box that allows you to search for options. It uses the [Tom Select library](https://tom-select.js.org/) under the hood.

  ## Usage:

    ```heex
    <.combobox
      id="widget_category_names"
      options={@widget_category_options}
    />

    <.combobox
      id="widget_category_names_multiple"
      options={@widget_category_options}
      multiple
    />

    <.combobox
      id="widget_category_names_multiple"
      options={@widget_category_options}
      create
    />

    <.field
      type="combobox"
      label="With placeholder"
      description="You can select only one option"
      placeholder="Select an option.."
      field={@form[:widget_category_names]}
    />

    <.field
      type="combobox"
      label="With prompt"
      description="You can select only one option"
      prompt="Select an option.."
      field={@form[:widget_category_names]}
    />
    ```

  ## Remote data source

  If you want to use your live view as a remote data source, you can set the `remote_options_event_name` option, which is
  similar to a `phx-change` event. When a user starts typing this will trigger an event with the name you pass. You handle
  the event in your live veiw return a list of options. The event will be passed the search term as first argument.

    ```heex
    <.field
      type="combobox"
      label="Remote single"
      description="You can select only one option"
      placeholder="Select an option.."
      remote_options_event_name="combobox_search"
      field={@form[:widget_category_names]}
    />
    ```

    ```elixir
    # @impl true
    def handle_event("combobox_search", payload, socket) do

      # `payload` will be a string ("some search term")

      # Do your search and turn the results into a list of maps with `text` and `value` keys
      results =
        Widget.search_widget_categories(payload)
        |> Enum.map(&%{text: &1.name, value: &1.name})

      # Make sure you return a map with a `results` key. The value of the `results` key must be a list of maps with `text` and `value` keys
      {:reply, %{results: results}, socket}
    end
    ```
  """

  attr :class, :string, default: nil, doc: "the class to add to the input"

  attr :id, :any,
    required: true,
    doc: "the id of the input (if used inside a form field, it will be automatically set)"

  attr :name, :any, doc: "the name of the input (if used inside a form field, it will be automatically set)"

  attr :value, :any, default: nil, doc: "the value of the input"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :placeholder, :string, default: nil, doc: "The placeholder text"

  attr :options, :list,
    doc: ~s|A list of options. eg. ["Admin", "User"] (label and value will be the same) or
      if you want the value to be different from the label: ["Admin": "admin", "User": "user"].
      We use https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2 underneath.|,
    default: []

  attr :multiple, :boolean, default: false, doc: "can multiple choices be selected?"
  attr :create, :boolean, default: false, doc: "create new options on the fly?"
  attr :max_items, :integer, default: nil, doc: "The maximum number of items that can be selected"

  attr :max_options, :integer,
    default: 100,
    doc: "The maximum number of options that can be displayed"

  attr :tom_select_plugins, :map,
    default: %{},
    doc: ~s|Which plugins should be activated? Pass a map that will be converted to a Javascript object via JSON.
      eg. `%{remove_button: %{title: "Remove!"}}`. See https://tom-select.js.org/plugins for available plugins.|

  attr :remote_options_event_name, :string,
    default: nil,
    doc: "The event name to trigger when searching for remote options. That event must return a list
      wrapped in a map with a `results` key. eg. `%{results: [%{text: \"Admin\", value: \"admin\"}]}`"

  attr :remove_button_title, :string, default: nil, doc: "The title for the remove item button"
  attr :add_text, :string, default: nil, doc: "The text for the add item action"

  attr :no_results_text, :string,
    default: nil,
    doc: "The text for when there are no results found"

  attr :tom_select_options, :map,
    default: %{},
    doc: "Options to pass to Tom Select. Uses camel case. eg `%{maxOptions: 1000}`.
      See https://tom-select.js.org/docs for options."

  attr :tom_select_options_global_variable, :string,
    default: nil,
    doc: ~s|for when you want to manually pass the options to Tom Select. eg. inside some script tags:
      `window.myOptions = { render: {...}}`. And in your component:`tom_select_options_global_variable="myOptions"`.
      It will merge the options with the existing ones.|

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step aria-invalid aria-describedby on-change),
    doc: "All other props go on the input"

  def combobox(assigns) do
    # if max_items is set, automatically convert to multiple options
    assigns =
      if assigns.multiple == false && is_number(assigns.max_items) && assigns.max_items > 1,
        do: assign(assigns, :multiple, true),
        else: assigns

    tom_select_options = merge_tom_select_options(assigns)
    tom_select_plugins = merge_tom_select_plugins(assigns)

    assigns =
      assigns
      |> handle_multiple_name()
      |> coerce_placeholder_and_prompt()
      |> assign(:tom_select_options_json, Jason.encode!(tom_select_options))
      |> assign(:tom_select_plugins_json, Jason.encode!(tom_select_plugins))

    ~H"""
    <div
      id={@id}
      phx-hook="ComboboxHook"
      data-options={@tom_select_options_json}
      data-plugins={@tom_select_plugins_json}
      data-global-options={@tom_select_options_global_variable}
      data-remote-options-event-name={@remote_options_event_name}
      class={["relative", @class]}
      {@rest}
    >
      <select class="combobox-latest hidden" multiple={@multiple}>
        <option :if={@prompt} value=""><%= @prompt %></option>
        <option :if={@placeholder} value=""><%= @placeholder %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>

      <input
        type="hidden"
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("hidden", "")}
        readonly
        hidden
        style="position: fixed; top: 1px; left: 1px; width: 1px; height: 0px; padding: 0px; margin: -1px; overflow: hidden; clip: rect(0px, 0px, 0px, 0px); white-space: nowrap; border-width: 0px; display: none;"
      />

      <div phx-update="ignore" id={"#{@id}_wrapper"}>
        <div class="combobox-wrapper opacity-0">
          <select
            id={"#{@id}_select"}
            name={@maybe_multiple_name}
            class="combobox"
            multiple={@multiple}
            {@rest}
            placeholder={@placeholder}
          >
            <option :if={@prompt} value=""><%= @prompt %></option>
            <option :if={@placeholder} value=""><%= @placeholder %></option>
            <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
          </select>
        </div>
      </div>
    </div>
    """
  end

  defp handle_multiple_name(assigns) do
    # ensure the name is set
    name =
      if is_nil(assigns[:name]),
        do: assigns.id,
        else: assigns.name

    # If we have multiple options and the combobox is wrapped in a form field or input, then we need to
    # remove the `[]` form the name (which was added by the .field / .input component)
    name =
      if assigns.multiple && String.ends_with?(name, "[]"),
        do: String.replace_suffix(name, "[]", ""),
        else: name

    # Add the `[]` to the maybe_multiple_name if it's multiple for the select box
    maybe_multiple_name =
      if assigns.multiple && !String.ends_with?(name, "[]"),
        do: name <> "[]",
        else: name

    assigns
    |> assign(:name, name)
    |> assign(:maybe_multiple_name, maybe_multiple_name)
  end

  # If we have a prompt and a placeholder, then remove the placeholder
  defp coerce_placeholder_and_prompt(assigns) do
    if assigns.prompt && assigns.placeholder do
      assign(assigns, :placeholder, nil)
    else
      assigns
    end
  end

  defp merge_tom_select_options(assigns) do
    %{
      create: assigns.create,
      maxItems: assigns.max_items,
      maxOptions: assigns.max_options,
      addText: assigns.add_text || ~t"Add",
      noResultsText: assigns.no_results_text || ~t"No results found for"
    }
    |> Map.merge(assigns.tom_select_options)
    |> remove_nil_keys()
  end

  defp merge_tom_select_plugins(assigns) do
    assigns.tom_select_plugins
    # If multiple, then add the checkbox plugin by default
    |> maybe_add_plugin(:checkbox_options, %{}, !!assigns.multiple)
    |> maybe_add_plugin(
      :remove_button,
      %{
        title: assigns.remove_button_title || ~t"Remove this item"
      },
      true
    )
    |> maybe_add_plugin(:dropdown_input, %{}, true)
    |> remove_falsy_keys()
  end

  defp maybe_add_plugin(plugins, _plugin, _value, false), do: plugins

  defp maybe_add_plugin(plugins, plugin, value, true) do
    Map.put_new(plugins, plugin, value)
  end

  defp remove_falsy_keys(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      if value,
        do: Map.put_new(acc, key, value),
        else: acc
    end)
  end

  defp remove_nil_keys(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      if value != nil,
        do: Map.put_new(acc, key, value),
        else: acc
    end)
  end
end
