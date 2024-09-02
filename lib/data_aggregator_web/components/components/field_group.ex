defmodule DataAggregatorWeb.Components.FieldGroup do
  @moduledoc """
  Provides components for grouping fields together.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Components.Field,
    only: [errors: 1, description: 1, label: 1, translate_error: 1]

  import DataAggregatorWeb.Components.Input, only: [input: 1]

  alias Phoenix.HTML.FormField

  @doc """
  Checkbox group input field.

  ## Example

  ```heex
  <.checkbox_group field={@form[:roles]} multiple options={["admin", "user", "customer"]} />
  ```
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"

  attr :options, :list, doc: "the options to pass to `DataAggregatorWeb.Components.FieldGroup.options_for_group/1`"

  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"

  attr :rest, :global, include: ~w(autocomplete disabled placeholder readonly required)

  slot :inner_block
  slot :custom_label, doc: "the slot for the label text (if you need to customize it)"

  def checkbox_group(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> checkbox_group()
  end

  def checkbox_group(assigns) do
    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} {@rest} />
      <% end %>
      <.input type="hidden" name={@name} value="" disabled={@rest[:disabled]} />
      <.description :if={@description} description={@description} class="mb-2" />
      <.description :if={length(@options) == 0} description={~t"No entries found"m} class="mb-2" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mb-2"} />
      <div class="grid grid-flow-row sm:grid-cols-2 sm:gap-x-2">
        <div
          :for={{label, value} <- options_for_group(@options)}
          class="flex cursor-pointer justify-between gap-4 py-2 sm:flex-row-reverse sm:justify-end"
        >
          <.label for={"#{@name}-#{value}"} label={label} class="cursor-pointer min-w-0 flex-1" />
          <input
            type="checkbox"
            id={"#{@name}-#{value}"}
            name={@name}
            value={value}
            checked={checked?(value, @value)}
            class="checkbox"
            {@rest}
          />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Radio group input field.

  ## Example

  ```heex
  <.radio_group field={@form[:roles]} options={["admin", "user", "customer"]} pills />
  ```
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"

  attr :options, :list, doc: "the options to pass to `DataAggregatorWeb.Components.FieldGroup.options_for_group/1`"

  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"

  attr :pills, :boolean, default: false, doc: "whether to render the radio group as pills"

  attr :rest, :global, include: ~w(autocomplete disabled placeholder readonly required)

  slot :inner_block
  slot :custom_label, doc: "the slot for the label text (if you need to customize it)"

  def radio_group(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> radio_group()
  end

  def radio_group(assigns) do
    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} {@rest} />
      <% end %>
      <.description :if={@description} description={@description} class="mb-2" />
      <.description :if={length(@options) == 0} description={~t"No entries found"m} class="mb-2" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mb-2"} />
      <div class={[
        @pills == true &&
          "ps-6 max-w-[100vw] no-scrollbar -mx-6 -mt-4 flex overflow-auto py-1 sm:max-w-3xl",
        @pills == false && "join grid auto-cols-fr grid-flow-col"
      ]}>
        <input
          :for={{label, value} <- options_for_group(@options)}
          type="radio"
          id={"#{@name}-#{value}"}
          name={@name}
          value={value}
          checked={checked?(value, @value)}
          class={[
            @pills == true &&
              "btn min-h-[auto] min-w-[59px] text-base-content border-base-content/20 leading-[18px] mr-2.5 inline-block h-auto overflow-clip rounded-3xl bg-transparent px-5 py-2.5 text-sm font-normal checked:!bg-base-content checked:!text-base-100 checked:!border-base-content hover:bg-base-100 hover:border-base-content focus-visible:!outline-base-content",
            @pills == false &&
              "join-item btn btn-lg text-base-content border-base-content/20 overflow-clip bg-transparent text-sm font-medium checked:!bg-base-content checked:!text-base-100 checked:!border-base-content hover:bg-base-100 hover:border-base-content focus-visible:!outline-base-content sm:text-base/5"
          ]}
          aria-label={label}
          {@rest}
        />
      </div>
    </div>
    """
  end

  @doc """
  Toggle group input field.

  ## Example

  ```heex
  <.toggle_group field={@form[:roles]} multiple options={["admin", "user", "customer"]} />
  ```
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"

  attr :options, :list, doc: "the options to pass to `DataAggregatorWeb.Components.FieldGroup.options_for_group/1`"

  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"

  attr :rest, :global, include: ~w(autocomplete disabled placeholder readonly required)

  slot :inner_block
  slot :custom_label, doc: "the slot for the label text (if you need to customize it)"

  def toggle_group(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> toggle_group()
  end

  def toggle_group(assigns) do
    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} {@rest} />
      <% end %>
      <.input type="hidden" name={@name} value="" disabled={@rest[:disabled]} />
      <.description :if={@description} description={@description} class="mb-2" />
      <.description :if={length(@options) == 0} description={~t"No entries found"m} class="mb-2" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mb-2"} />
      <div class="grid grid-flow-row sm:grid-cols-2 sm:gap-x-2">
        <div
          :for={{label, value} <- options_for_group(@options)}
          class="flex cursor-pointer justify-between gap-4 py-2 sm:flex-row-reverse sm:justify-end"
        >
          <.label for={"#{@name}-#{value}"} label={label} class="cursor-pointer min-w-0 flex-1" />
          <input
            type="checkbox"
            id={"#{@name}-#{value}"}
            name={@name}
            value={value}
            checked={checked?(value, @value)}
            class="toggle"
            {@rest}
          />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Returns options to be used inside a checkgroup or radio group.

  ## Examples

      iex> options_for_group(["Admin": "admin", "User": "user"])
      [
        {"Admin", "admin"},
        {"User", "user"}
      ]

  Simple arrays of strings are supported:

      iex> options_for_group(["UK", "Sweden", "France"])
      [
        {"UK", "UK"},
        {"Sweden", "Sweden"},
        {"France", "France"}
      ]

  Simple array of atoms are supported:

      iex> options_for_group([:uk, :se, :fr])
      [
        {"uk", "uk"},
        {"se", "se"},
        {"fr", "fr"}
      ]

  Key value pairs are also supported:

      iex> options_for_group([[key: "UK", value: "uk"], [key: "Sweden", value: "se"], [key: "France", value: "fr"]])
      [
        {"UK", "uk"},
        {"Sweden", "se"},
        {"France", "fr"}
      ]
  """
  def options_for_group(options) do
    Enum.map(options, fn
      {key, value} ->
        {to_string(key), to_string(value)}

      options when is_list(options) ->
        {option_key, options} = Keyword.pop(options, :key)

        option_key ||
          raise ArgumentError,
                "expected :key key when building <group options> from keyword list: #{inspect(options)}"

        {option_value, options} = Keyword.pop(options, :value)

        option_value ||
          raise ArgumentError,
                "expected :value key when building <group options> from keyword list: #{inspect(options)}"

        {to_string(option_key), to_string(option_value)}

      str when is_binary(str) ->
        {str, str}

      atom when is_atom(atom) ->
        {Atom.to_string(atom), Atom.to_string(atom)}
    end)
  end

  @doc """
  Returns true if the value is checked, false otherwise.

  ## Examples

      iex> checked?("admin", ["admin", "user"])
      true

      iex> checked?("admin", "admin")
      true

      iex> checked?("admin", "user")
      false
  """
  @spec checked?(String.t(), list() | String.t() | nil) :: boolean()
  def checked?(value, options)
  def checked?(_, nil), do: false
  def checked?(value, options) when is_list(options), do: value in options
  def checked?(value, option), do: value == option
end
