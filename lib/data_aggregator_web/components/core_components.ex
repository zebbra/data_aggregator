defmodule DataAggregatorWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such as modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias DataAggregatorWeb.HeadlessComponents
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Headless.Dialog, only: [dialog_title: 1]
  import DataAggregatorWeb.QueryBuilder

  @doc ~S"""
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={Enum.member?(["server-error", "client-error"], @id) == false && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg shadow-lg ring-1",
        @kind == :info && "bg-green-50 ring-green-500",
        @kind == :error && "bg-red-50 ring-red-500"
      ]}
      {@rest}
    >
      <div class="p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <.icon
              :if={@kind == :info}
              name="hero-information-circle-mini text-green-400"
              class="w-6 h-6"
            />
            <.icon
              :if={@kind == :error}
              name="hero-exclamation-circle-mini text-red-400"
              class="w-6 h-6"
            />
          </div>

          <div class="flex-1 pt-0.5 ml-3 w-0">
            <p
              :if={@title}
              class={[
                "text-sm font-medium text-gray-900 mb-2",
                @kind == :info && "text-green-800",
                @kind == :error && "text-red-800"
              ]}
            >
              <%= @title %>
            </p>
            <p class={[
              "text-sm",
              @kind == :info && "text-green-700",
              @kind == :error && "text-red-700"
            ]}>
              <%= msg %>
            </p>
          </div>

          <div class="flex flex-shrink-0 ml-4">
            <button
              type="button"
              class={[
                "inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2",
                @kind == :info &&
                  "bg-green-50 text-green-500 hover:bg-green-100 focus:ring-green-600 focus:ring-offset-green-50",
                @kind == :error &&
                  "bg-red-50 text-red-500 hover:bg-red-100 focus:ring-red-600 focus:ring-offset-red-50"
              ]}
              aria-label={gettext("close")}
            >
              <.icon name="hero-x-mark-solid" class="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :class, :string, default: nil, doc: "the flash group class"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <div
        aria-live="assertive"
        class="sm:items-start sm:p-6 fixed inset-0 flex items-end px-4 py-6 pointer-events-none"
      >
        <div class="sm:items-end flex flex-col items-center w-full space-y-4">
          <.flash kind={:info} title={~t"Success!"m} flash={@flash} hidden />
          <.flash kind={:error} title={~t"Error!"m} flash={@flash} hidden />
          <.flash
            id="client-error"
            kind={:error}
            title={~t"We can't find the internet"m}
            phx-disconnected={show(".phx-client-error #client-error")}
            phx-connected={hide("#client-error")}
            hidden
          >
            <%= ~t"Attempting to reconnect"m %>
            <.icon name="hero-arrow-path" class="animate-spin w-3 h-3 ml-1" />
          </.flash>

          <.flash
            id="server-error"
            kind={:error}
            title="Something went wrong!"
            phx-disconnected={show(".phx-server-error #server-error")}
            phx-connected={hide("#server-error")}
            hidden
          >
            <%= ~t"Hang in there while we get back on track"m %>
            <.icon name="hero-arrow-path" class="animate-spin w-3 h-3 ml-1" />
          </.flash>
        </div>
      </div>
    </div>
    """
  end

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
      <div class="dark:bg-gray-900 mt-8 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="sm:mt-4 sm:flex sm:flex-row-reverse mt-5">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc ~S"""
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: "button", doc: "the button type (button, submit)"
  attr :class, :string, default: nil, doc: "the button class"

  attr :variant, :string,
    default: "primary",
    doc: "the button variant (primary, secondary, accent, nav, table)"

  attr :rest, :global,
    include: ~w(disabled form name value),
    doc: "the arbitrary HTML attributes to apply to the button tag"

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 text-sm font-semibold disabled:opacity-75 disabled:pointer-events-none select-none",
        button_class(@variant),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc ~S"""
  Renders a link with the same styling variants as the buttons.

  ## Examples

      <.style_link navigate={~p"/"} >Home</.style_link>
  """
  attr :class, :string, default: nil, doc: "the link class"

  attr :variant, :string,
    default: "primary",
    doc: "the link variant (primary, secondary, accent, nav, table)"

  attr :rest, :global,
    include: ~w(navigate patch href replace method csrf_token disabled),
    doc: "the arbitrary HTML attributes to apply to the link tag"

  slot :inner_block, required: true

  def styled_link(assigns) do
    ~H"""
    <.link
      class={[
        "phx-submit-loading:opacity-75 text-sm font-semibold select-none inline-flex",
        button_class(@variant),
        @rest[:disabled] && "opacity-75 pointer-events-none",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp button_class(variant) do
    case variant do
      "primary" ->
        [
          "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 dark:focus-visible:outline-indigo-500 rounded-md shadow-sm py-2 px-3",
          "dark:bg-indigo-500 dark:hover:bg-indigo-400 bg-indigo-600 hover:bg-indigo-500 text-white active:text-white/80 rounded-md shadow-sm"
        ]

      "secondary" ->
        "hover:bg-gray-50 ring-1 ring-inset ring-gray-300 text-gray-900 bg-white dark:hover:bg-gray-900 dark:hover:text-gray-300 dark:ring-0 dark:text-white dark:bg-gray-900 rounded-md shadow-sm py-2 px-3"

      "accent" ->
        "bg-red-600 dark:bg-red-500 hover:bg-red-500 dark:hover:bg-red-400 text-white active:text-white/80 rounded-md shadow-sm py-2 px-3"

      "nav" ->
        "relative inline-flex items-center bg-white px-3 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-400/10 focus:z-10 dark:text-white dark:bg-white/10 dark:ring-0 dark:hover:bg-white/20 py-2 px-3"

      "table" ->
        "hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 font-semibold leading-6 text-indigo-600"
    end
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

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "radio"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("radio", assigns[:value]) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="dark:text-white flex items-center gap-3 text-sm font-medium leading-6 text-gray-900">
        <input type="hidden" name={@name} value="false" />
        <input
          type="radio"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="dark:border-white/10 dark:bg-white/5 checked:bg-current checked:border-transparent dark:checked:bg-current dark:checked:border-transparent focus:ring-indigo-600 dark:focus:ring-offset-gray-900 w-4 h-4 text-indigo-600 border-gray-300"
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors} id={"#{@id}-error"}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="dark:text-white flex items-center gap-3 text-sm font-medium leading-6 text-gray-900">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="dark:border-white/10 dark:bg-white/5 checked:bg-current checked:border-transparent dark:checked:bg-current dark:checked:border-transparent focus:ring-indigo-600 dark:focus:ring-offset-gray-900 w-4 h-4 text-indigo-600 border-gray-300 rounded"
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors} id={"#{@id}-error"}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <div class={[
        "mt-2",
        @errors != [] && "relative rounded-md shadow-md phx-no-feedback:shadow-none"
      ]}>
        <select
          id={@id}
          name={@name}
          class={[
            "block w-full rounded-md border-0 py-1.5 shadow-sm ring-1 ring-inset placeholder:text-gray-400 focus:ring-2 focus:ring-inset sm:text-sm sm:leading-6",
            "text-gray-900 dark:text-white dark:bg-white/5",
            "phx-no-feedback:ring-gray-300 dark:phx-no-feedback:ring-white/10 phx-no-feedback:focus:ring-indigo-600 dark:phx-no-feedback:focus:ring-indigo-500",
            @errors == [] &&
              "ring-gray-300 focus:ring-indigo-600 dark:ring-white/10 dark:focus:ring-indigo-500",
            @errors != [] &&
              "ring-red-300 dark:ring-red-400 focus:ring-red-500 dark:focus:ring-red-500"
          ]}
          multiple={@multiple}
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        >
          <option :if={@prompt} value=""><%= @prompt %></option>
          <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
        </select>
        <div
          :if={@errors != []}
          class="phx-no-feedback:hidden absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none"
        >
          <.icon name="hero-exclamation-circle-mini" class="w-5 h-5 text-red-500" />
        </div>
      </div>
      <.error :for={msg <- @errors} id={"#{@id}-error"}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <div class={[
        "mt-2",
        @errors != [] && "relative rounded-md shadow-md phx-no-feedback:shadow-none"
      ]}>
        <textarea
          id={@id}
          name={@name}
          class={[
            "block w-full rounded-md border-0 py-1.5 shadow-sm ring-1 ring-inset placeholder:text-gray-400 focus:ring-2 focus:ring-inset sm:text-sm sm:leading-6",
            "text-gray-900 dark:text-white dark:bg-white/5",
            "phx-no-feedback:ring-gray-300 dark:phx-no-feedback:ring-white/10 phx-no-feedback:focus:ring-indigo-600 dark:phx-no-feedback:focus:ring-indigo-500",
            @errors == [] &&
              "ring-gray-300 focus:ring-indigo-600 dark:ring-white/10 dark:focus:ring-indigo-500",
            @errors != [] &&
              "ring-red-300 dark:ring-red-400 focus:ring-red-500 dark:focus:ring-red-500"
          ]}
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
        <div
          :if={@errors != []}
          class="phx-no-feedback:hidden absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none"
        >
          <.icon name="hero-exclamation-circle-mini" class="w-5 h-5 text-red-500" />
        </div>
      </div>
      <.error :for={msg <- @errors} id={"#{@id}-error"}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <div class={[
        "mt-2",
        @errors != [] && "relative rounded-md shadow-md phx-no-feedback:shadow-none"
      ]}>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "block w-full rounded-md border-0 py-1.5 shadow-sm ring-1 ring-inset placeholder:text-gray-400 focus:ring-2 focus:ring-inset sm:text-sm sm:leading-6",
            "text-gray-900 dark:text-white dark:bg-white/5",
            "phx-no-feedback:ring-gray-300 dark:phx-no-feedback:ring-white/10 phx-no-feedback:focus:ring-indigo-600 dark:phx-no-feedback:focus:ring-indigo-500",
            @errors == [] &&
              "ring-gray-300 focus:ring-indigo-600 dark:ring-white/10 dark:focus:ring-indigo-500",
            @errors != [] &&
              "ring-red-300 dark:ring-red-400 focus:ring-red-500 dark:focus:ring-red-500"
          ]}
          aria-invalid={@errors != []}
          aria-describedby={@errors != [] && "#{@id}-error"}
          {@rest}
        />
        <div
          :if={@errors != []}
          class="phx-no-feedback:hidden absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none"
        >
          <.icon name="hero-exclamation-circle-mini" class="w-5 h-5 text-red-500" />
        </div>
      </div>
      <.error :for={msg <- @errors} id={"#{@id}-error"}><%= msg %></.error>
    </div>
    """
  end

  @doc ~S"""
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="dark:text-white block text-sm font-medium leading-6 text-gray-900">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc ~S"""
  Generates a generic error message.
  """
  attr :id, :string
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p id={@id} class="phx-no-feedback:hidden mt-2 text-sm text-red-600">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc ~S"""
  Renders a header with title.
  """
  attr :class, :string, default: nil, doc: "the header class"
  attr :action_class, :string, default: "flex gap-x-3"

  attr :id, :string, default: nil

  attr :dialog_header_id, :string,
    default: nil,
    doc: "if set we assume a dialog header and use the dialog_header component"

  slot :inner_block, required: true
  slot :subtitle, doc: "the optional subtitle displayed below the title"
  slot :actions, doc: "the optional actions displayed on the right side of the header"

  def header(assigns) do
    ~H"""
    <header class={[
      "dark:bg-gray-900 z-10 bg-white border-b dark:border-white/5 border-gray-200 p-4 sm:py-5 sm:px-6 lg:px-8 w-full",
      @actions != [] &&
        "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <.dialog_title
          :if={@dialog_header_id}
          id={@dialog_header_id <> "__title"}
          class="dark:text-white text-base font-semibold leading-9 text-gray-800"
        >
          <%= render_slot(@inner_block) %>
        </.dialog_title>
        <h1
          :if={!@dialog_header_id}
          class="dark:text-white text-base font-semibold leading-9 text-gray-800 outline-none"
        >
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="dark:text-gray-400 mt-2 text-sm leading-6 text-gray-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class={@action_class}><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a sidebar with header, inner_block, and footer slots with default tailwindui style.
  """
  attr :class, :string, default: nil, doc: "the sidebar class"
  attr :as, :string, default: "div"

  slot :inner_block, required: true
  slot :header, doc: "the optional header slot, displayed sticky at top"
  slot :footer, doc: "the optional footer slot, displayed sticky at bottom"

  def sidebar(assigns) do
    ~H"""
    <.dynamic_tag
      name={@as}
      class={[
        "flex flex-col h-full bg-gray-100/30 dark:bg-black/10 shadow-xl border-l border-b border-gray-200 dark:border-white/10 divide-y divide-gray-200 dark:divide-white/5",
        @class
      ]}
    >
      <div class="overscroll-contain no-scrollbar flex flex-col flex-1 min-h-0 pb-6 overflow-y-scroll">
        <%= render_slot(@header) %>
        <div class="relative flex-1">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
      <div
        :if={@footer != []}
        class="dark:bg-gray-900 flex justify-end flex-shrink-0 px-4 py-4 bg-white"
      >
        <%= render_slot(@footer) %>
      </div>
    </.dynamic_tag>
    """
  end

  @doc ~S"""
  Renders a table for streams with generic tailwindui styling.

  ## Examples

      <.table id="users" rows={@streams.results}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true, doc: "the list of rows (a stream) to render"
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :sort, :string, default: nil, doc: "the current sort order"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string, doc: "the label for the column"
    attr :field, :string, doc: "the field for the column"
    attr :sort, :boolean, doc: "the sort flag for the column"
    attr :align, :string, doc: "the alignment of the column (left, center, right)"
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    assigns = assign(assigns, :sort_dir, current_sort_dir(assigns.sort))
    assigns = assign(assigns, :sort_field, current_sort_field(assigns.sort))

    ~H"""
    <div class="sm:px-6 lg:px-8 px-4">
      <div class="sm:mt-6 lg:mt-8 flow-root mt-4">
        <div class="table-container sm:-mx-6 lg:-mx-8 no-scrollbar overscroll-x-contain -mx-4 -my-2 overflow-x-auto">
          <div class="inline-block min-w-full py-2 align-middle">
            <table
              role="table"
              class="will-change-scroll dark:divide-gray-700 min-w-full divide-y divide-gray-300 table-auto"
            >
              <thead role="rowgroup">
                <tr role="row">
                  <th
                    :for={col <- @col}
                    role="columnheader"
                    scope="col"
                    class="first:pl-4 last:pl-3 first:pr-3 last:pr-4 dark:text-white first:sm:pl-6 first:lg:pl-8 last:sm:pr-6 last:lg:pr-8 py-3.5 px-3 text-sm font-semibold tracking-wide text-left text-gray-900 uppercase whitespace-nowrap"
                  >
                    <%= if col[:sort] do %>
                      <span
                        class="group inline-flex cursor-pointer select-none"
                        phx-click="sort:select"
                        phx-value-sort={col[:field]}
                      >
                        <span :if={col[:align] != "right"}><%= col[:label] %></span>
                        <span class={[
                          "flex-none rounded text-gray-400 dark:text-gray-500",
                          col[:align] == "right" && "mr-2",
                          col[:align] != "right" && "ml-2",
                          @sort_field != col[:field] &&
                            "invisible group-hover:visible group-focus:visible",
                          @sort_field == col[:field] &&
                            "rounded bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-white group-hover:bg-gray-200 dark:group-hover:bg-gray-700"
                        ]}>
                          <svg
                            :if={@sort_dir == "asc"}
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            class="w-5 h-5"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M14.77 12.79a.75.75 0 01-1.06-.02L10 8.832 6.29 12.77a.75.75 0 11-1.08-1.04l4.25-4.5a.75.75 0 011.08 0l4.25 4.5a.75.75 0 01-.02 1.06z"
                              clip-rule="evenodd"
                            />
                          </svg>
                          <svg
                            :if={@sort_dir == "desc"}
                            class="w-5 h-5"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                              clip-rule="evenodd"
                            >
                            </path>
                          </svg>
                        </span>
                        <span :if={col[:align] == "right"}><%= col[:label] %></span>
                      </span>
                    <% else %>
                      <%= col[:label] %>
                    <% end %>
                  </th>
                  <th
                    :if={@action != []}
                    role="columnheader"
                    scope="col"
                    class="sm:pr-6 lg:pr-8 relative py-3.5 pr-4 pl-3"
                  >
                    <span class="sr-only"><%= gettext("Actions") %></span>
                  </th>
                </tr>
              </thead>
              <tbody
                id={@id}
                role="rowgroup"
                phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
                class="dark:divide-gray-800 divide-y divide-gray-200"
              >
                <tr
                  :for={row <- @rows}
                  role="rowgroup"
                  id={@row_id && @row_id.(row)}
                  class={[
                    "group",
                    row_selected(row) &&
                      "bg-gray-500/5 dark:bg-gray-400/10",
                    !row_selected(row) && "dark:hover:bg-black/10 hover:bg-gray-400/10"
                  ]}
                >
                  <td
                    :for={{col, _i} <- Enum.with_index(@col)}
                    phx-click={@row_click && @row_click.(row)}
                    role="cell"
                    class={[
                      "whitespace-nowrap py-4 px-3 first:pl-4 first:pr-3 last:pl-3 last:pr-4 text-sm first:font-medium text-gray-900 dark:text-white first:sm:pl-6 first:lg:pl-8 last:sm:pr-6 last:lg:pr-8",
                      @row_click && "hover:cursor-pointer"
                    ]}
                  >
                    <%= render_slot(col, @row_item.(row)) %>
                  </td>
                  <td
                    :if={@action != []}
                    role="cell"
                    class="whitespace-nowrap sm:pr-6 lg:pr-8 relative py-4 pl-3 pr-4 text-sm font-medium text-right"
                  >
                    <span
                      :for={action <- @action}
                      class="hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 relative ml-4 font-semibold leading-6 text-indigo-600"
                    >
                      <%= render_slot(action, @row_item.(row)) %>
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Private function to determine if the row is selected
  defp row_selected({_id, row}) when is_map(row) do
    row
    |> Map.has_key?(:selected) && row.selected == true
  end

  defp row_selected(_row), do: false

  @doc ~S"""
  Renders offset pagination with generic styling.
  """

  attr :page_meta, Ash.Page.Offset, required: true

  def pagination(assigns) do
    [from, to] = paginate_page_meta(assigns.page_meta)

    assigns =
      assigns
      |> assign(:from, from)
      |> assign(:to, to)

    ~H"""
    <div
      class="border-y dark:border-white/10 bg-gray-100/30 dark:bg-black/10 sm:px-6 lg:px-8 flex items-center justify-between px-4 py-4 border-gray-200"
      role="navigation"
    >
      <div class="sm:hidden flex justify-between flex-1">
        <.button
          variant="nav"
          class="rounded-md"
          aria-label={~t"Previous"m}
          disabled={@page_meta.offset == 0}
          phx-click="page:prev"
        >
          <%= ~t"Prev"m %>
        </.button>
        <.page_size_select id="page-size-select-mobile" current_limit={@page_meta.limit} />
        <.button
          variant="nav"
          class="rounded-md"
          aria-label={~t"Next"m}
          disabled={@page_meta.more? == false}
          phx-click="page:next"
        >
          <%= ~t"Next"m %>
        </.button>
      </div>
      <div class="sm:flex sm:flex-1 sm:items-center sm:justify-between hidden">
        <div>
          <p class="dark:text-gray-400 text-sm text-gray-700">
            <%= ~t"Showing"m %> <span class="font-medium"><%= @from %></span>
            <%= ~t"to"m %>
            <span class="font-medium"><%= @to %></span>
            <%= ~t"of"m %> <span class="font-medium"><%= @page_meta.count %></span>
            <%= ~t"results"m %>
          </p>
        </div>
        <div class="flex items-center">
          <.page_size_select id="page-size-select" current_limit={@page_meta.limit} />
          <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <.button
              variant="nav"
              class="rounded-l-md"
              aria-label={~t"Previous"m}
              disabled={@page_meta.offset == 0}
              phx-click="page:prev"
            >
              <%= ~t"Prev"m %>
            </.button>
            <.button
              variant="nav"
              class="rounded-r-md -ml-px"
              aria-label={~t"Next"m}
              disabled={@page_meta.more? == false}
              phx-click="page:next"
            >
              <%= ~t"Next"m %>
            </.button>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :current_limit, :integer, required: true

  defp page_size_select(assigns) do
    ~H"""
    <div class="flex items-center mr-2 space-x-2">
      <.label for={@id}>
        <%= ~t"Page size"m %>
      </.label>
      <HeadlessComponents.menu id={@id}>
        <HeadlessComponents.menu_button id={@id <> "__button"} as="div" class="">
          <.button variant="nav" class="rounded-md">
            <%= @current_limit %>
          </.button>
        </HeadlessComponents.menu_button>
        <HeadlessComponents.menu_items
          id={@id <> "__items"}
          position="bottom-right"
          width="w-[4.5rem]"
        >
          <div class="py-1" role="none">
            <HeadlessComponents.menu_item
              :for={page_size <- [5, 10, 15, 20, 25, 50, 100]}
              id={@id <> "__item-" <> to_string(page_size)}
              as="div"
              phx-click="page:change"
              phx-value-limit={page_size}
            >
              <%= page_size %>
              <span :if={@current_limit == page_size} class="text-cyan-600 font-bold">
                &check;
              </span>
            </HeadlessComponents.menu_item>
          </div>
        </HeadlessComponents.menu_items>
      </HeadlessComponents.menu>
    </div>
    """
  end

  @doc ~S"""
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class="dark:divide-white/5 w-full divide-y divide-gray-200">
      <div :for={item <- @item} class="px-6 py-5">
        <dt class="dark:text-white text-sm font-medium text-gray-500">
          <%= item.title %>
        </dt>
        <dd class="dark:text-gray-200 mt-1 text-sm text-gray-700">
          <%= render_slot(item) %>
        </dd>
      </div>
    </dl>
    """
  end

  @doc ~S"""
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="sm:px-6 lg:px-8 px-4 mt-16">
      <.link
        navigate={@navigate}
        class="hover:text-gray-700 dark:text-white dark:hover:text-gray-300 text-sm font-semibold leading-6 text-gray-900"
      >
        <.icon name="hero-arrow-left-solid" class="w-3 h-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc ~S"""
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="animate-spin w-3 h-3 ml-1" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    js
    |> JS.show(
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-2 sm:translate-y-0 sm:translate-x-2",
         "opacity-100 translate-y-0 sm:translate-x-0"}
    )
    |> JS.remove_attribute("hidden", to: selector)
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 100,
      transition: {"transition-all transform ease-in duration-100", "opacity-100", "opacity-0"}
    )
  end

  @doc ~S"""
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

  @doc ~S"""
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
