defmodule DataAggregatorWeb.Components.Field do
  @moduledoc """
  Field components.
  """
  use Phoenix.Component

  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias Phoenix.HTML.Form

  @valid_inside_types ~w(email number password tel text url search)

  @doc """
  Renders an input with label, description, and error messages.
  The layout is highly opinionated and may not fit your needs. In that case,
  you may use the custom_field component.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

  ```heex
  <.field field={@form[:email]} type="email" />
  <.field name="my-input" errors={["oh no!"]} />
  ```
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week combobox checkgroup)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :inline, :boolean, default: false, doc: "whether the field is inline"
  attr :inside, :boolean, default: false, doc: "whether the field is inside"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"
  attr :icon_start, :string, default: nil, doc: "icon name for the start of the input"
  attr :icon_end, :string, default: nil, doc: "icon name for the end of the input"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step
                create max_items max_options tom_select_plugins tom_select_options remote_options_event_name dropup)

  slot :inner_block
  slot :custom_label, doc: "the slot for the label text (if you need to customize it)"
  slot :before_input, doc: "the slot for the region before the input (only for inside)"
  slot :after_input, doc: "the slot for the region after the input (only for inside)"

  def field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> field()
  end

  def field(%{type: "checkgroup"} = assigns) do
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
      <div class="grid grid-flow-row sm:grid-cols-2">
        <div
          :for={{label, value} <- options_for_checkgroup(@options)}
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

  def field(%{type: "toggle"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div class={[
      "form-control grid items-center gap-x-4 gap-y-1",
      @class,
      @inline && "sm:col-span-3",
      @hidden && "hidden"
    ]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} class="col-start-1 row-start-1 pb-0" {@rest} />
      <% end %>
      <.description :if={@description} description={@description} class="col-start-1 row-start-2" />
      <.input {assigns} class="col-start-2 row-start-1 justify-self-end" />
      <.errors
        errors={@errors}
        id={@id}
        class={if(@description, do: "col-start-1 row-start-3", else: "col-start-1 row-start-2")}
      />
    </div>
    """
  end

  def field(%{type: "checkbox", inline: true} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div class={[
      "form-control grid items-center gap-x-4 gap-y-1 sm:col-span-3",
      @class,
      @hidden && "hidden"
    ]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} class="col-start-1 row-start-1 pb-0" {@rest} />
      <% end %>
      <.description :if={@description} description={@description} class="col-start-1 row-start-2" />
      <.input {assigns} class="col-start-2 row-start-1 justify-self-end" />
      <.errors
        errors={@errors}
        id={@id}
        class={if(@description, do: "col-start-1 row-start-3", else: "col-start-1 row-start-2")}
      />
    </div>
    """
  end

  def field(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div class={[
      "form-control grid-cols-[1.5rem] grid items-center gap-x-4 gap-y-1",
      @class,
      @hidden && "hidden"
    ]}>
      <.input {assigns} class="col-start-1 row-start-1 justify-self-center" />
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label
          :if={@label}
          for={@id}
          label={@label}
          class="col-start-2 row-start-1 justify-self-start pb-0"
          {@rest}
        />
      <% end %>
      <.description :if={@description} description={@description} class="col-start-2 row-start-2" />
      <.errors
        errors={@errors}
        id={@id}
        class={if(@description, do: "col-start-2 row-start-3", else: "col-start-2 row-start-2")}
      />
    </div>
    """
  end

  def field(%{type: "radio", inline: true} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("radio", assigns[:value]) end)

    ~H"""
    <div class={[
      "form-control grid items-center gap-x-4 gap-y-1 sm:col-span-3",
      @class,
      @hidden && "hidden"
    ]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} class="col-start-1 row-start-1 pb-0" {@rest} />
      <% end %>
      <.description :if={@description} description={@description} class="col-start-1 row-start-2" />
      <.input {assigns} class="col-start-2 row-start-1 justify-self-end" />
      <.errors
        errors={@errors}
        id={@id}
        class={if(@description, do: "col-start-1 row-start-3", else: "col-start-1 row-start-2")}
      />
    </div>
    """
  end

  def field(%{type: "radio"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("radio", assigns[:checked]) end)

    ~H"""
    <div class={[
      "form-control grid-cols-[1.5rem] grid items-center gap-x-4 gap-y-1",
      @class,
      @hidden && "hidden"
    ]}>
      <.input class="col-start-1 row-start-1 justify-self-center" {assigns} />
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label
          :if={@label}
          for={@id}
          label={@label}
          class="col-start-2 row-start-1 justify-self-start pb-0"
          {@rest}
        />
      <% end %>
      <.description :if={@description} description={@description} class="col-start-2 row-start-2" />
      <.errors
        errors={@errors}
        id={@id}
        class={if(@description, do: "col-start-2 row-start-3", else: "col-start-2 row-start-2")}
      />
    </div>
    """
  end

  def field(%{type: "select", inline: true} = assigns) do
    ~H"""
    <div class={["form-control grid-cols-[subgrid] grid sm:col-span-3", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} class="sm:pb-0 sm:block" {@rest} />
      <% end %>
      <.input {assigns} class="sm:col-span-2" />
      <.description
        :if={@description}
        description={@description}
        class="sm:col-span-3 mt-3 sm:justify-self-end"
      />
      <.errors
        errors={@errors}
        id={@id}
        class={class_names(["sm:col-span-3 sm:justify-self-end", is_nil(@description) && "mt-2"])}
      />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def field(%{inline: true} = assigns) do
    ~H"""
    <div class={["form-control grid-cols-[subgrid] grid sm:col-span-3", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} class="sm:pb-0 sm:block" {@rest} />
      <% end %>
      <.input class="sm:col-span-2" {assigns} />
      <.description
        :if={@description}
        description={@description}
        class="sm:col-span-3 mt-3 sm:justify-self-end"
      />
      <.errors
        errors={@errors}
        id={@id}
        class={class_names(["sm:col-span-3 sm:justify-self-end", is_nil(@description) && "mt-2"])}
      />
    </div>
    """
  end

  def field(%{inside: true} = assigns) do
    # throw error if type is not in valid types
    unless Enum.member?(@valid_inside_types, assigns[:type]) do
      raise ArgumentError,
            "type must be one of #{inspect(@valid_inside_types)}, got: #{inspect(assigns[:type])}"
    end

    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <label for={@id} class="input input-bordered flex items-center gap-2">
        <%= if @label do %>
          <%= @label %>
        <% else %>
          <%= render_slot(@before_input) %>
        <% end %>
        <.input {assigns} />
        <%= render_slot(@after_input) %>
      </label>
      <.description :if={@description} description={@description} class="mt-3" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mt-2"} />
    </div>
    """
  end

  def field(assigns) do
    ~H"""
    <div class={["form-control w-full", @class, @hidden && "hidden"]}>
      <%= if @custom_label != [] do %>
        <%= render_slot(@custom_label) %>
      <% else %>
        <.label :if={@label} for={@id} label={@label} {@rest} />
      <% end %>
      <.input {assigns} />
      <.description :if={@description} description={@description} class="mt-3" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mt-2"} />
    </div>
    """
  end

  @doc """
  Renders a custom field. Requires the `:content` slot to be defined.
  Passes the `field` variable to the slot containing the processed
  `Phoenix.HTML.FormField` struct.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information.

  ## Examples

  ```heex
  <.custom_field field={f[:first_name]} label={~t"First name"m}>
    <:content :let={field}>
      <.label {field} required />
      <.input {field} />
      <.errors {field} class="mt-2" />
    </:content>
  </.custom_field>
  ```
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week combobox)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :hidden, :boolean, default: false, doc: "whether the field is hidden"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step
                create max_items max_options tom_select_plugins tom_select_options remote_options_event_name dropup)

  slot :content

  def custom_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> custom_field()
  end

  def custom_field(assigns) do
    ~H"""
    <div class={["form-control", @class, @hidden && "hidden"]}>
      <%= render_slot(@content, assigns) %>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :label, :string, default: nil, doc: "the label text"
  attr :class, :string, default: nil, doc: "additional css class for description"
  attr :required, :boolean, default: false
  attr :disabled, :boolean, default: false

  slot :inner_block, doc: "the slot for the label text if no label is given"

  def label(assigns) do
    ~H"""
    <label for={@for} class={["label px-0 pt-0", @class]}>
      <span class={[
        "label-text text-sm/6 truncate font-medium",
        @required && "after:content-['*']",
        @disabled && "text-base-content/50"
      ]}>
        <%= if @label do %>
          <%= @label %>
        <% else %>
          <%= render_slot(@inner_block) %>
        <% end %>
      </span>
    </label>
    """
  end

  @doc """
  Renders a description.
  """
  attr :description, :string, default: nil, doc: "the description text"
  attr :class, :string, default: nil, doc: "additional css class for description"

  slot :inner_block, doc: "the slot for the description text if no description is given"

  def description(assigns) do
    ~H"""
    <p class={["text-base-content/60 text-sm/6", @class]}>
      <%= if @description do %>
        <%= @description %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </p>
    """
  end

  @doc """
  Generates a generic error message.
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :errors, :list, required: true

  def errors(assigns) do
    ~H"""
    <p :if={@errors != []} id={"#{@id}_error"} class={["text-base/6 sm:text-sm/6", @class]}>
      <span :for={msg <- @errors} class="text-error"><%= msg %></span>
    </p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(DataAggregatorWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DataAggregatorWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Returns options to be used inside a checkgroup.

  ## Examples

      iex> options_for_checkgroup(["Admin": "admin", "User": "user"])
      [
        {"Admin", "admin"},
        {"User", "user"}
      ]

  Simple arrays of strings are supported:

      iex> options_for_checkgroup(["UK", "Sweden", "France"])
      [
        {"UK", "UK"},
        {"Sweden", "Sweden"},
        {"France", "France"}
      ]

  Simple array of atoms are supported:

      iex> options_for_checkgroup([:uk, :se, :fr])
      [
        {"uk", "uk"},
        {"se", "se"},
        {"fr", "fr"}
      ]

  Key value pairs are also supported:

      iex> options_for_checkgroup([[key: "UK", value: "uk"], [key: "Sweden", value: "se"], [key: "France", value: "fr"]])
      [
        {"UK", "uk"},
        {"Sweden", "se"},
        {"France", "fr"}
      ]
  """
  def options_for_checkgroup(options) do
    Enum.map(options, fn
      {key, value} ->
        {to_string(key), to_string(value)}

      options when is_list(options) ->
        {option_key, options} = Keyword.pop(options, :key)

        option_key ||
          raise ArgumentError,
                "expected :key key when building <checkgroup options> from keyword list: #{inspect(options)}"

        {option_value, options} = Keyword.pop(options, :value)

        option_value ||
          raise ArgumentError,
                "expected :value key when building <checkgroup options> from keyword list: #{inspect(options)}"

        {to_string(option_key), to_string(option_value)}

      str when is_binary(str) ->
        {str, str}

      atom when is_atom(atom) ->
        {Atom.to_string(atom), Atom.to_string(atom)}
    end)
  end

  defp checked?(value, options)
  defp checked?(_, nil), do: false
  defp checked?(value, options), do: value in options
end
