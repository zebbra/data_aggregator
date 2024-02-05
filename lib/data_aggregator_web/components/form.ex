defmodule DataAggregatorWeb.Components.Form do
  @moduledoc """
  Renders a simple form.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]

  alias Phoenix.HTML.Form

  @doc ~S"""
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse sm:gap-4">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc ~S"""
  Renders an input with label and error messages.

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

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additinal css class for input"

  attr :rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    # |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div phx-feedback-for={@name} class="form-control">
      <input type="hidden" name={@name} value="false" />
      <label class="label cursor-pointer justify-start space-x-4">
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox"
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
        <span class="label-text"><%= @label %></span>
      </label>

      <.errors errors={@errors} />
    </div>
    """
  end

  def input(%{type: "radio"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("radio", assigns[:value]) end)

    ~H"""
    <div phx-feedback-for={@name} class="form-control">
      <input type="hidden" name={@name} value="false" />
      <label class="label cursor-pointer justify-start space-x-4">
        <input
          type="radio"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="radio"
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
        <span class="label-text"><%= @label %></span>
      </label>

      <.errors errors={@errors} />
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      class={["form-control w-full", @errors != [] && "[&_select]:phx-feedback:select-error"]}
    >
      <.label :if={@label} for={@id}><%= @label %></.label>

      <select
        id={@id}
        name={@name}
        class={["select select-bordered", @class]}
        multiple={@multiple}
        aria-invalid={@errors != []}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>

      <.errors errors={@errors} />
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="form-control w-full">
      <.label :if={@label} for={@id}><%= @label %></.label>

      <textarea
        name={@name}
        id={@id}
        class={["textarea textarea-bordered", @errors != [] && "phx-feedback:textarea-error", @class]}
        aria-invalid={@errors != []}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>

      <.errors errors={@errors} />
    </div>
    """
  end

  def input(%{type: "range"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="form-control w-full">
      <.label :if={@label} for={@id}><%= @label %></.label>

      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value("range", @value)}
        class={["range", @errors != [] && "phx-feedback:range-error", @class]}
        aria-invalid={@errors != []}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      />

      <.errors errors={@errors} />
    </div>
    """
  end

  def input(%{type: "search"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="form-control w-full">
      <.label :if={@label} for={@id}><%= @label %></.label>

      <div class="relative w-full">
        <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <.icon name="hero-magnifying-glass" class="w-5 h-5 text-base-content/50" />
        </div>

        <input
          type="search"
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "input input-bordered !pl-10 w-full rounded-full",
            @errors != [] && "phx-feedback:input-error",
            @class
          ]}
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
      </div>

      <.errors errors={@errors} />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="form-control w-full">
      <.label :if={@label} for={@id}><%= @label %></.label>

      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={["input input-bordered", @errors != [] && "input-error", @class]}
        aria-invalid={@errors != []}
        aria-describedby={@errors != [] && "#{@id}-error"}
        {@rest}
      />

      <.errors errors={@errors} />
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="label">
      <span class="label-text">
        <%= render_slot(@inner_block) %>
      </span>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  attr :errors, :list, required: true

  def errors(assigns) do
    ~H"""
    <label :if={@errors != []} class="label phx-no-feedback:hidden">
      <span :for={msg <- @errors} class="label-text-alt text-error"><%= msg %></span>
    </label>
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
end
