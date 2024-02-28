defmodule DataAggregatorWeb.Components.Input do
  @moduledoc """
  Input components.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias Phoenix.HTML.Form

  @valid_inside_types ~w(email number password tel text url search)

  @doc """
  Renders an input.

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
  attr(:id, :any, default: nil)
  attr(:name, :any)
  attr(:label, :string, default: nil)
  attr(:value, :any)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week toggle combobox)
  )

  attr(:field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]")

  attr(:errors, :list, default: [])
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:class, :string, default: nil, doc: "additional css class for input")
  attr(:inline, :boolean, default: false, doc: "whether the fieldgroup is inline")
  attr(:inside, :boolean, default: false, doc: "whether the field is inside")
  attr(:icon_start, :string, default: nil, doc: "icon name for the start of the input")
  attr(:icon_end, :string, default: nil, doc: "icon name for the end of the input")

  attr(:rest, :global, include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step))

  slot(:inner_block)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, field.errors)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input
      type="checkbox"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      class={["checkbox", @class, @errors != [] && "phx-feedback:checkbox-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  def input(%{type: "toggle"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input
      type="checkbox"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      class={["toggle", @class, @errors != [] && "phx-feedback:checkbox-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  def input(%{type: "radio"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("radio", assigns[:value]) end)

    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input
      type="radio"
      id={@id}
      name={@name}
      value="true"
      checked={@checked}
      class={["radio", @class, @errors != [] && "phx-feedback:radio-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <select
      id={@id}
      name={@name}
      class={["select select-bordered", @class, @errors != [] && "phx-feedback:select-error"]}
      multiple={@multiple}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    >
      <option :if={@prompt} value=""><%= @prompt %></option>
      <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
    </select>
    """
  end

  def input(%{type: "combobox"} = assigns) do
    ~H"""
    <input type="hidden" input-id={@id} value="false" />
    <x-combobox
      id={@id}
      name={@name}
      class={[@class, @errors != [] && "[&_.input]:phx-feedback:input-error"]}
      phx-update="ignore"
      multiple={@multiple}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      data-placeholder={@rest[:placeholder]}
      data-options={Jason.encode!(@options)}
      data-value={@value}
      {@rest}
    />
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <textarea
      id={@id}
      name={@name}
      class={[
        "textarea textarea-bordered max-sm:text-base",
        @class,
        @errors != [] && "phx-feedback:textarea-error"
      ]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
    """
  end

  def input(%{type: "range"} = assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value("range", @value)}
      class={["range", @class, @errors != [] && "phx-feedback:range-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  def input(%{type: "file"} = assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value("file", @value)}
      class={[
        "file file-input file-input-bordered",
        @class,
        @errors != [] && "phx-feedback:file-input-error"
      ]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  # All other inside inputs text, datetime-local, url, password, etc. are handled here...
  def input(%{inside: true} = assigns) do
    # throw error if type is not in valid types
    unless Enum.member?(@valid_inside_types, assigns[:type]) do
      raise ArgumentError,
            "type must be one of #{inspect(@valid_inside_types)}, got: #{inspect(assigns[:type])}"
    end

    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={["grow", @class, @errors != [] && "phx-feedback:input-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  # All other inline inputs text, datetime-local, url, password, etc. are handled here...
  def input(%{icon_start: nil, icon_end: nil, inline: true} = assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={["input input-bordered", @class, @errors != [] && "phx-feedback:input-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(%{icon_start: nil, icon_end: nil} = assigns) do
    ~H"""
    <input
      type={@type}
      id={@id}
      name={@name}
      value={Phoenix.HTML.Form.normalize_value(@type, @value)}
      class={["input input-bordered", @class, @errors != [] && "phx-feedback:input-error"]}
      aria-invalid={@errors != []}
      aria-describedby={@errors != [] && "#{@id}_error"}
      {@rest}
    />
    """
  end

  def input(%{icon_start: _, icon_end: nil} = assigns) do
    ~H"""
    <div class={["relative w-full", @inline && @class]}>
      <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
        <.icon
          name={@icon_start}
          class={
            class_names(["size-5 text-base-content/50", @errors != [] && "phx-feedback:text-error"])
          }
        />
      </div>
      <%= input(%{assigns | icon_start: nil, class: class_names(["w-full pl-10", @class])}) %>
    </div>
    """
  end

  def input(%{icon_start: nil, icon_end: _} = assigns) do
    ~H"""
    <div class={["relative w-full", @inline && @class]}>
      <%= input(%{assigns | icon_end: nil, class: class_names(["w-full pr-10", @class])}) %>
      <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
        <.icon
          name={@icon_end}
          class={
            class_names(["size-5 text-base-content/50", @errors != [] && "phx-feedback:text-error"])
          }
        />
      </div>
    </div>
    """
  end

  def input(%{icon_start: _, icon_end: _} = assigns) do
    ~H"""
    <div class={["relative w-full", @inline && @class]}>
      <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
        <.icon
          name={@icon_start}
          class={
            class_names(["size-5 text-base-content/50", @errors != [] && "phx-feedback:text-error"])
          }
        />
      </div>
      <%= input(%{
        assigns
        | icon_start: nil,
          icon_end: nil,
          class: class_names(["w-full pl-10 pr-10", @class])
      }) %>
      <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
        <.icon
          name={@icon_end}
          class={
            class_names(["size-5 text-base-content/50", @errors != [] && "phx-feedback:text-error"])
          }
        />
      </div>
    </div>
    """
  end
end
