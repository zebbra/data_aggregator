defmodule DataAggregatorWeb.Components.Form do
  @moduledoc """
  Form components.
  """
  use Phoenix.Component

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.Modal, only: [modal_header: 1, modal_footer: 1]

  @doc """
  Renders a simple form.

  ## Examples

  ```heex
  <.simple_form for={@form} phx-change="validate" phx-submit="save">
    <.field field={@form[:email]} label="Email"/>
    <.field field={@form[:username]} label="Username" />
    <:actions>
      <button type="submit" class="btn btn-primary">Save</button>
    </:actions>
  </.simple_form>
  ```

  You have the possibility to render the form inside a modal with sticky header and footer.
  Checkout the modal component for more information about sticky modals. Sticky modal forms
  can be built in the following ways:

  1. You have only one fieldset and want to use the legend as title and actions as footer. In
  this case you can use the `modal` attribute on the simple_form, fieldset, fieldgroup and
  actions slots. Furthermore, you have to wrap the `<.simple_form>` in a div with the class
  `contents`. This ensures that the form is displayed correctly within the modal.

  ```heex
  <.modal overflow="manual">
    <.live_component
      module={FormComponent}
      id="entity_modal"
    >
      <div class="contents> <!-- This is important -->
        <.simple_form
          for={@form}
          id="entity_form"
          novalidate
          phx-target={@myself}
          phx-change="entity:validate"
          phx-submit="entity:save"
          modal <!-- This is important -->
        >
          <.fieldset
            legend="New Entity"
            text="Use this form to manage entities in your database."
            modal <!-- This is important -->
          >
            <.fieldgroup modal> <!-- This is important -->
              ...
            </.fieldgroup>
            <:actions modal> <!-- This is important -->
              <button type="submit" class="btn btn-primary">Save</button>
            </:actions>
          </.fieldset>
        </.simple_form>
      </div>
    </.live_component>
  </.modal>
  ```

  2. You want more control over the header and the form itself. In this case you will
  make use of the `<.modal_header>` component to render the header. The `<.fieldset>`
  must be wrapped in a div with the class `h-full overflow-y-auto` to make it scroll.
  The actions are rendered in the footer of the modal. To make them sticky, you have to
  add the `modal` attribute to the actions slot.

  ```heex
  <.modal overflow="manual">
    <.live_component
      module={FormComponent}
      id="entity_modal"
    >
      <div class="contents"> <!-- This is important -->
        <.modal_header id="entity_modal"> <!-- Sticky header -->
          <.section_heading
            text="New Entity"
            description="Use this form to manage entities in your database."
            size="md"
          />
        </.modal_header>
        <.simple_form
          for={@form}
          id="entity_form"
          novalidate
          phx-target={@myself}
          phx-change="entity:validate"
          phx-submit="entity:save"
          class="contents" <!-- This is important -->
        >
          <div class="h-full overflow-y-auto p-6"> <!-- Form content will scroll -->
            <.fieldset
              legend="New Entity"
              text="Use this form to manage entities in your database."
            >
              <.fieldgroup>
                ...
              </.fieldgroup>
            </.fieldset>
            <:actions modal> <!-- This is important -->
              <button type="submit" class="btn btn-primary">Save</button>
            </:actions>
          </div>
        </.simple_form>
      </div>
    </.live_component>
  </.modal>
  ```
  """
  attr :id, :string, default: "simple_form", doc: "the id of the form"
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :modal, :boolean,
    default: false,
    doc: "whether the form is inside a modal with sticky header and footer"

  attr :gradient, :boolean,
    default: true,
    doc: "whether to show a gradient above the actions (only for modal forms)"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true

  slot :actions, doc: "the slot for form actions, such as a submit button" do
    attr :class, :string, doc: "the class to apply to the actions container"

    attr :modal, :boolean, doc: "whether the actions are inside a modal with sticky header and footer"
  end

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} class={form_class(@modal, @rest)} {@rest}>
      {render_slot(@inner_block, f)}
      <.form_actions
        :for={action <- @actions}
        id={@id}
        gradient={@gradient}
        footer_class={action[:class]}
        modal={action[:modal]}
      >
        {render_slot(action)}
      </.form_actions>
    </.form>
    """
  end

  defp form_class(true, rest), do: "contents #{Map.get(rest, :class)}"
  defp form_class(false, rest), do: Map.get(rest, :class)

  defp form_actions(%{modal: true} = assigns) do
    ~H"""
    <.modal_footer id={@id} gradient={@gradient} footer_class={@footer_class}>
      {render_slot(@inner_block)}
    </.modal_footer>
    """
  end

  defp form_actions(assigns) do
    ~H"""
    <div class={@footer_class || "modal-action flex-row-reverse justify-start"}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Something has to hold all these form controls together.

  Use the <.fieldset /> and <.fieldgroup /> components to group a subset of form
  controls together:

  ## Examples

  ```heex
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
  ```
  """
  attr :id, :string, default: "fieldset", doc: "the id of the fieldset"
  attr :legend, :string, default: nil, doc: "the legend for the fieldset"
  attr :text, :string, default: nil, doc: "the text for the fieldset"
  attr :class, :string, default: nil, doc: "the class to apply to the fieldset"
  attr :disabled, :boolean, default: false, doc: "whether the fieldset is disabled"

  attr :legend_size, :string,
    default: "md",
    doc: "the size of the section_heading for the legend wrapper"

  attr :rest, :global, doc: "the arbitrary HTML attributes to apply to the fieldset tag"

  attr :modal, :boolean,
    default: false,
    doc: "whether the fieldset is inside a modal with sticky header and footer"

  attr :gradient, :boolean,
    default: true,
    doc: "whether to show a gradient below the title (only for modal fieldsets)"

  slot :inner_block, required: true

  slot :legend_actions, doc: "the slot for fieldset legend actions" do
    attr :class, :string, doc: "the class to apply to the actions container"
  end

  slot :actions, doc: "the slot for form actions, such as a submit button" do
    attr :class, :string, doc: "the class to apply to the actions container"

    attr :modal, :boolean, doc: "whether the actions are inside a modal with sticky header and footer"
  end

  def fieldset(assigns) do
    ~H"""
    <fieldset class={[fieldset_class(@modal), @class]} role="group" {@rest}>
      {if @legend || @text, do: fieldset_legend(assigns)}
      {render_slot(@inner_block)}
      <.fieldset_footer
        :for={action <- @actions}
        id={@id}
        gradient={@gradient}
        footer_class={action[:class]}
        modal={@modal}
      >
        {render_slot(action)}
      </.fieldset_footer>
    </fieldset>
    """
  end

  defp fieldset_class(modal)
  defp fieldset_class(false), do: "[&>*+[data-slot=control]]:mt-6"
  defp fieldset_class(true), do: "contents"

  slot :legend_actions, doc: "the slot for fieldset legend actions" do
    attr :class, :string, doc: "the class to apply to the actions container"
  end

  defp fieldset_legend(%{modal: true} = assigns) do
    assigns = assign(assigns, :modal, false)

    ~H"""
    <.modal_header id={@id} gradient={@gradient}>
      {fieldset_legend(assigns)}
    </.modal_header>
    """
  end

  defp fieldset_legend(%{modal: false} = assigns) do
    ~H"""
    <.section_heading
      as="legend"
      text={@legend}
      description={@text}
      size={@legend_size}
      align_items="center"
    >
      <:actions :for={action <- @legend_actions} class={action[:class]}>
        {render_slot(action)}
      </:actions>
    </.section_heading>
    """
  end

  defp fieldset_footer(%{modal: true} = assigns) do
    ~H"""
    <.modal_footer id={@id} gradient={@gradient} footer_class={@footer_class}>
      {render_slot(@inner_block)}
    </.modal_footer>
    """
  end

  defp fieldset_footer(assigns) do
    ~H"""
    <div class={@footer_class || "modal-action flex-row-reverse justify-start"}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A fieldgroup is a container for a group of fields.

  ## Examples

  ```heex
  <.fieldset legend="Personal Information">
    <.fieldgroup>
      <.field field={@f[:email]} label="Email"/>
      <.field field={@f[:username]} label="Username" />
    </.fieldgroup>
  </.fieldset>
  ```
  """
  attr :class, :string, default: "space-y-8", doc: "the class to apply to the fieldgroup"
  attr :inline, :boolean, default: false, doc: "whether the fieldgroup is inline"

  attr :modal, :boolean,
    default: false,
    doc: "whether the fieldgroup is inside a modal with sticky header and footer"

  slot :inner_block, required: true

  def fieldgroup(assigns) do
    ~H"""
    <div class={[fieldgroup_class(@inline, @modal), @class]} data-slot="control">
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp fieldgroup_class(inline, modal)

  defp fieldgroup_class(true, _), do: "grid grid-cols-1 items-center gap-x-4 gap-y-6 sm:grid-cols-3"

  defp fieldgroup_class(false, true), do: "h-full overflow-y-auto p-6"
  defp fieldgroup_class(_, _), do: ""
end
