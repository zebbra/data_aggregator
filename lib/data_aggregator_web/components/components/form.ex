defmodule DataAggregatorWeb.Components.Form do
  @moduledoc """
  Form components.
  """
  use Phoenix.Component

  alias Phoenix.HTML.Form

  import DataAggregatorWeb.Components.Input, only: [input: 1]
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.field field={@form[:email]} label="Email"/>
        <.field field={@form[:username]} label="Username" />
        <:actions>
          <button type="submit" class="btn btn-primary">Save</button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true

  slot :actions, doc: "the slot for form actions, such as a submit button" do
    attr :class, :string, doc: "the class to apply to the actions container"
  end

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <%= render_slot(@inner_block, f) %>
      <div :for={action <- @actions} class={[action[:class] || "modal-action"]}>
        <%= render_slot(action, f) %>
      </div>
    </.form>
    """
  end

  @doc """
  Something has to hold all these form controls together.

  Use the <.fieldset /> and <.fieldgroup /> components to group a subset of form
  controls together:

  ## Examples

      <.simple_form :let={f} for={%{}} as="user" phx-change="validate" phx-submit="save">
        <.fieldset legend="Personal Information">
          <.field field={@f[:email]} label="Email"/>
          <.field field={@f[:username]} label="Username" />
        </.fieldset>
        <.fieldset legend="Address">
          <.field field={@f[:address]} label="Address"/>
          <.field field={@f[:city]} label="City" />
          <.field field={@f[:state]} label="State" />
          <.field field={@f[:zip]} label="Zip" />
        </.fieldset>
        <:actions>
          <button type="submit" class="btn btn-primary">Save</button>
        </:actions>
      </.simple_form>
  """
  attr :legend, :string, default: nil, doc: "the legend for the fieldset"
  attr :text, :string, default: nil, doc: "the text for the fieldset"
  attr :class, :string, default: nil, doc: "the class to apply to the fieldset"
  attr :disabled, :boolean, default: false, doc: "whether the fieldset is disabled"
  attr :rest, :global, doc: "the arbitrary HTML attributes to apply to the fieldset tag"

  slot :inner_block, required: true

  def fieldset(assigns) do
    ~H"""
    <fieldset class={["[&>*+[data-slot=control]]:mt-6", @class]} role="group" {@rest}>
      <legend
        :if={@legend}
        class={[
          "label-text text-base/6 font-semibold sm:text-sm/6",
          @disabled && "text-base-content/50"
        ]}
      >
        <%= @legend %>
      </legend>
      <p
        :if={@text}
        class={[
          "mt-1 text-base leading-6 sm:text-sm",
          if(@disabled, do: "text-base-content/50", else: "text-base-content/60")
        ]}
      >
        <%= @text %>
      </p>
      <%= render_slot(@inner_block) %>
    </fieldset>
    """
  end

  attr :class, :string, default: "space-y-8", doc: "the class to apply to the fieldgroup"
  attr :inline, :boolean, default: false, doc: "whether the fieldgroup is inline"
  slot :inner_block, required: true

  def fieldgroup(assigns) do
    ~H"""
    <div
      class={[@inline && "grid grid-cols-1 items-center gap-x-4 gap-y-6 sm:grid-cols-3", @class]}
      data-slot="control"
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

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

      <.field field={@form[:email]} type="email" />
      <.field name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"
  attr :inline, :boolean, default: false, doc: "whether the field is inline"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> field()
  end

  def field(%{type: "toggle"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div
      phx-feedback-for={@name}
      class={["form-control grid items-center gap-x-4 gap-y-1", @inline && "sm:col-span-3"]}
    >
      <.label :if={@label} for={@id} label={@label} class="col-start-1 row-start-1 pb-0" {@rest} />
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
    <div phx-feedback-for={@name} class="form-control grid items-center gap-x-4 gap-y-1 sm:col-span-3">
      <.label :if={@label} for={@id} label={@label} class="col-start-1 row-start-1 pb-0" {@rest} />
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
    <div
      phx-feedback-for={@name}
      class="form-control grid-cols-[1.5rem] grid items-center gap-x-4 gap-y-1"
    >
      <.input class="col-start-1 row-start-1 justify-self-center" {assigns} />
      <.label
        :if={@label}
        for={@id}
        label={@label}
        class="col-start-2 row-start-1 justify-self-start pb-0"
        {@rest}
      />
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
    <div phx-feedback-for={@name} class="form-control grid items-center gap-x-4 gap-y-1 sm:col-span-3">
      <.label :if={@label} for={@id} label={@label} class="col-start-1 row-start-1 pb-0" {@rest} />
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
      assign_new(assigns, :checked, fn -> Form.normalize_value("radio", assigns[:value]) end)

    ~H"""
    <div
      phx-feedback-for={@name}
      class="form-control grid-cols-[1.5rem] grid items-center gap-x-4 gap-y-1"
    >
      <.input class="col-start-1 row-start-1 justify-self-center" {assigns} />
      <.label
        :if={@label}
        for={@id}
        label={@label}
        class="col-start-2 row-start-1 justify-self-start pb-0"
        {@rest}
      />
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
    <div
      phx-feedback-for={@name}
      class={[
        "form-control grid-cols-[subgrid] grid sm:col-span-3",
        @errors != [] && "[&_select]:phx-feedback:select-error"
      ]}
    >
      <.label :if={@label} for={@id} label={@label} class="sm:pb-0 sm:block" {@rest} />
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

  def field(%{type: "select"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      class={["form-control w-full", @errors != [] && "[&_select]:phx-feedback:select-error"]}
    >
      <.label :if={@label} for={@id} label={@label} {@rest} />
      <.input {assigns} />
      <.description :if={@description} description={@description} class="mt-3" />
      <.errors errors={@errors} id={@id} class={is_nil(@description) && "mt-2"} />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def field(%{inline: true} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="form-control grid-cols-[subgrid] grid sm:col-span-3">
      <.label :if={@label} for={@id} label={@label} class="sm:pb-0 sm:block" {@rest} />
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

  def field(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="form-control w-full">
      <.label :if={@label} for={@id} label={@label} {@rest} />
      <.input {assigns} />
      <.description :if={@description} class="mt-3">
        <%= @description %>
      </.description>
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

      <.custom_field field={f[:first_name]} label={~t"First name"m}>
        <:content :let={field}>
          <.label {field} required />
          <.input {field} />
          <.errors {field} class="mt-2" />
        </:content>
      </.custom_field>
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :description, :string, default: nil, doc: "the description for the input"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "additional css class for input"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

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
    <div phx-feedback-for={@name} class={["form-control", @class]}>
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
        "label-text text-base/6 font-medium sm:text-sm/6",
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
    <p class={["text-base-content/60 text-base/6 sm:text-sm/6", @class]}>
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
    <p
      :if={@errors != []}
      id={"#{@id}-error"}
      class={["text-base/6 phx-no-feedback:hidden sm:text-sm/6", @class]}
    >
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
end
