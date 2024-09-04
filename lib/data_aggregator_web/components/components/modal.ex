defmodule DataAggregatorWeb.Components.Modal do
  @moduledoc """
  Modal components.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.Button, only: [close_button: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  Modals should be placed within the `:portal` slot of the Layout component.

  ## Examples

  ```heex
  <.modal id="confirm_modal">
    This is a modal.
  </.modal>
  ```

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

  ```heex
  <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
    This is another modal.
  </.modal>
  ```

  ## Modal with a form

  The modal component is designed to be used with a form. In this case you should use
  backdrop={false} attr to prevent outside clicks from closing the modal. Further, you have
  to push the submit:close event on successfull form submit to the client. This event
  is handled in the dialog.hook.ts DialogHook and will manually close the dialog. If you
  control the modal with the :if directive combined with the show attr, you do not need
  to push this event.

  For example:

  ```heex
  <.modal id="user_modal" responsive backdrop={false} on_cancel={JS.patch(~p"/users")}>
    <.simple_form
      :let={f}
      for={%{}}
      as={:user}
      phx-submit={JS.push("save_user")}
    >
      <.fieldset legend="Create new user" text="This won't be persisted into DB, memory only.">
        <.fieldgroup>
          <.field field={f[:first_name]} label="First name" required />
          <.field field={f[:last_name]} label="Last name" required />
          <.field field={f[:email]} label="EMail" type="email" required />
          <.field field={f[:age]} label="Age" type="number" required />
        </.fieldgroup>
      </.fieldset>
      <:actions>
        <button type="button" class="btn btn-ghost" onclick="user_modal.close()">
          Cancel
        </button>
        <button type="reset" class="btn btn-ghost">Reset</button>
        <button type="submit" class="btn btn-primary">Save user</button>
      </:actions>
    </.simple_form>
  </.modal>
  ```

  ## Sticky header and footer

  The modal component supports sticky header and footer. To use this feature, you have to
  use the header and footer slots (or the title attribute). For example:

  ```heex
  <.modal id="sticky_modal">
    <:header>
      <h1 class="text-lg font-bold">Sticky header</h1>
    </:header>
    This is a sticky modal. The body will scroll.
    <:footer>
      <button class="btn btn-primary">Save</button>
    </:footer>
  </.modal>
  ```

  > **Note**:
  > If you want to use a form with a sticky header and footer, you have to set the overflow
  > attr to `manual` and handle the sticky form header and footer manually. Have a look at the
  > form component for more information.
  """
  attr :id, :string, required: true, doc: "The modal ID."
  attr :class, :string, default: nil, doc: "Additional CSS classes to add to the modal box."
  attr :show, :boolean, default: false, doc: "Whether the modal visibility is controlled."
  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the modal is closed."
  attr :on_confirm, JS, default: %JS{}, doc: "JS commands to run when the modal is closed."
  attr :responsive, :boolean, default: false, doc: "Show at bottom on small screens."
  attr :backdrop, :boolean, default: true, doc: "Show a backdrop behind the modal."

  attr :overflow, :string,
    values: ["auto", "manual"],
    default: "auto",
    doc: "If set to manual, the default modal overflow behaviour will be removed."

  attr :size, :string,
    values: ["xs", "sm", "md", "lg", "xl", "2xl", "3xl", "4xl", "5xl", nil],
    default: nil

  attr :wrapper_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the modal wrapper."

  attr :modal_body_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the modal body."

  attr :title, :string, default: nil, doc: "The modal header."

  attr :title_wrapper_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the title wrapper."

  attr :title_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the title"

  attr :description, :string,
    default: nil,
    doc: "The optional description (subtitle)"

  attr :gradient, :boolean, default: true, doc: "Whether to show a gradient below the title"

  attr :close_button_position, :string,
    values: ["left", "right"],
    default: "right",
    doc: "The position of the close button."

  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the modal box."

  slot :header, doc: "The sticky modal header." do
    attr :class, :string, doc: "Additional CSS classes to add to the header slot."
  end

  slot :footer, doc: "The sticky modal footer." do
    attr :class, :string, doc: "Additional CSS classes to add to the footer slot."

    attr :reverse, :boolean,
      doc: """
      Whether to reverse the order of the footer items.

      Usefull to enforce that the submit button is focused first.
      Default is true.
      """
  end

  slot :inner_block, required: true, doc: "The modal content."

  def modal(assigns) do
    ~H"""
    <dialog
      id={@id}
      role="dialog"
      class={[
        "modal",
        @responsive && "modal-bottom max-sm:items-end sm:modal-middle",
        wrapper_class(@header, @footer, @title, @overflow),
        @wrapper_class
      ]}
      phx-hook="DialogHook"
      data-show={@show}
      data-cancel={@on_cancel}
      data-confirm={@on_confirm}
    >
      <div class="contents">
        <.focus_wrap
          id={"#{@id}_content"}
          class={[
            "modal-box max-h-[calc(100dvh-2em)] sm:max-h-[calc(100dvh-5em)]",
            focus_wrap_class(@header, @footer, @title, @overflow),
            size(@size),
            @class
          ]}
        >
          <div class="contents">
            <.modal_header
              :for={header <- @header}
              id={@id}
              title_wrapper_class={header[:class]}
              title_class={@title_class}
              on_cancel={@on_cancel}
              close_button_position={@close_button_position}
              gradient={@gradient}
            >
              <%= render_slot(header) %>
            </.modal_header>

            <.modal_header
              :if={@title}
              id={@id}
              title={@title}
              title_wrapper_class={@title_wrapper_class}
              title_class={@title_class}
              description={@description}
              on_cancel={@on_cancel}
              close_button_position={@close_button_position}
              gradient={@gradient}
            />

            <div
              id={"#{@id}_body"}
              class={[modal_body_class(@header, @footer, @title, @overflow), @modal_body_class]}
            >
              <%= render_slot(@inner_block) %>
            </div>

            <.modal_footer
              :for={footer <- @footer}
              id={@id}
              footer_class={footer[:class]}
              reverse={if is_nil(footer[:reverse]), do: true, else: footer[:reverse]}
              gradient={@gradient}
            >
              <%= render_slot(@footer) %>
            </.modal_footer>
          </div>
          <.close_button as="form" method="dialog" position={@close_button_position} />
        </.focus_wrap>
      </div>
      <form
        :if={@backdrop}
        method="dialog"
        class={["modal-backdrop", backdrop_class(@header, @footer, @title, @overflow)]}
      >
        <button><%= ~t"close"m %></button>
      </form>
    </dialog>
    """
  end

  @doc """
  Renders a sticky modal header.

  ## Examples

  ```heex
  <.header>
    <h1 class="text-lg font-bold">Sticky header</h1>
  </.header>
  ```

  Or with a title

  ```heex
  <.header title="Sticky header" />
  ```
  """
  attr :id, :string, required: true, doc: "The modal ID."
  attr :title, :string, default: nil, doc: "The modal header."

  attr :title_wrapper_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the title wrapper."

  attr :title_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the title."

  attr :description, :string,
    default: nil,
    doc: "The optional description (subtitle)"

  attr :gradient, :boolean, default: true, doc: "Whether to show a gradient below the title"

  attr :close_button, :boolean, default: false, doc: "Whether to show a close button."

  attr :close_button_position, :string,
    values: ["left", "right"],
    default: "right",
    doc: "The position of the close button."

  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the modal is closed."

  slot :inner_block, doc: "The header content."

  def modal_header(assigns) do
    ~H"""
    <header id={"#{@id}_header"} class="relative">
      <div class={[title_wrapper_class(@close_button_position), @title_wrapper_class]}>
        <div :if={@close_button_position == "left"} class="shrink-0 grow-0 basis-4 text-left" />
        <div class={[title_class(@close_button_position), @title_class]}>
          <%= if @title do %>
            <.section_heading text={@title} description={@description} size="md" />
          <% else %>
            <%= render_slot(@inner_block) %>
          <% end %>
        </div>
        <div class="shrink-0 grow-0 basis-4 text-right" />
      </div>
      <div
        :if={@gradient}
        class="from-base-100 bottom-[-1.5rem] absolute z-10 h-6 w-full bg-gradient-to-b"
      />

      <.close_button :if={@close_button} position={@close_button_position} on_cancel={@on_cancel} />
    </header>
    """
  end

  defp title_wrapper_class(close_button_position)

  defp title_wrapper_class("left"),
    do: "border-black-white/10 min-h-12 flex items-center justify-between border-b px-6 py-4 sm:min-h-16"

  defp title_wrapper_class("right"),
    do: "border-black-white/10 min-h-12 flex items-center justify-start border-b px-6 py-4 sm:min-h-16"

  defp title_class(close_button_position)
  defp title_class("left"), do: "shrink mx-4 grow-0 basis-auto overflow-hidden"
  defp title_class("right"), do: "shrink mr-4 grow-0 basis-auto overflow-hidden"

  @doc """
  Renders a sticky modal footer.

  ## Examples

  ```heex
  <.footer>
    <button class="btn btn-primary">Save</button>
  </.footer>
  ```
  """
  attr :id, :string, required: true, doc: "The modal ID."

  attr :footer_class, :string,
    default: nil,
    doc: "Additional CSS classes to use for the footer."

  attr :gradient, :boolean, default: true, doc: "Whether to show a gradient above the footer."

  attr :reverse, :boolean,
    default: true,
    doc: """
    Whether to reverse the order of the footer items.

    Usefull to enforce that the submit button is focused first.
    Default is true.
    """

  slot :inner_block, required: true, doc: "The footer content."

  def modal_footer(assigns) do
    ~H"""
    <footer id={"#{@id}_footer"} class="relative">
      <div :if={@gradient} class="from-base-100 top-[-1.5rem] absolute h-6 w-full bg-gradient-to-t" />
      <div class={[
        "border-black-white/10 modal-action mt-0 flex items-center justify-start border-t px-6 py-4",
        @reverse && "flex-row-reverse justify-start",
        @footer_class
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
    </footer>
    """
  end

  defp wrapper_class(header, footer, title, overflow)
  defp wrapper_class([], [], nil, "auto"), do: ""
  defp wrapper_class(_, _, _, _), do: "flex h-full items-center justify-center pt-3 sm:p-[40px]"

  defp backdrop_class(header, footer, title, overflow)
  defp backdrop_class([], [], nil, "auto"), do: ""
  defp backdrop_class(_, _, _, _), do: "absolute inset-0"

  defp focus_wrap_class(header, footer, title, overflow)
  defp focus_wrap_class([], [], nil, "auto"), do: ""

  defp focus_wrap_class([], [], _, "auto"), do: "flex flex-col overflow-clip max-h-full relative px-0 pt-0"

  defp focus_wrap_class(_, [], _, "auto"), do: "flex flex-col overflow-clip max-h-full relative px-0 pt-0"

  defp focus_wrap_class([], _, nil, "auto"), do: "flex flex-col overflow-clip max-h-full relative px-0 pb-0"

  defp focus_wrap_class(_, _, _, _), do: "flex flex-col overflow-clip max-h-full relative p-0"

  defp modal_body_class(header, footer, title, overflow)
  defp modal_body_class([], [], nil, "auto"), do: ""
  defp modal_body_class([], [], _, "auto"), do: "h-full overflow-y-auto px-6 pt-6"
  defp modal_body_class(_, [], _, "auto"), do: "h-full overflow-y-auto px-6 pt-6"
  defp modal_body_class([], _, nil, "auto"), do: "h-full overflow-y-auto px-6 pb-6"
  defp modal_body_class(_, _, _, "auto"), do: "h-full overflow-y-auto p-6"
  defp modal_body_class(_, _, _, "manual"), do: "contents"

  defp size(nil), do: ""

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp size(size) do
    case size do
      "xs" -> "sm:max-w-xs"
      "sm" -> "sm:max-w-sm"
      "md" -> "sm:max-w-md"
      "lg" -> "sm:max-w-lg"
      "xl" -> "sm:max-w-xl"
      "2xl" -> "sm:max-w-2xl"
      "3xl" -> "sm:max-w-3xl"
      "4xl" -> "sm:max-w-4xl"
      "5xl" -> "sm:max-w-5xl"
      _ -> "sm:max-w-5xl"
    end
  end
end
