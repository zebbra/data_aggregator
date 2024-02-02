defmodule DataAggregatorWeb.Components.Modal do
  @moduledoc """
  Modal components.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  ## Modal with a form

  The modal component is designed to be used with a form. In this case you should use
  backdrop={false} attr to prevent outside clicks from closing the modal. Further, you have
  to chain the phx-submit JS command with |> JS.dispatch("submit:form"). This event
  is handled in the modal.hook.ts ModalHook and will manually close the dialog. If you
  control the modal with the :if directive combined with the show attr, you do not need
  to chain the JS command.

  For example:

      <.modal id="user_modal" responsive backdrop={false} on_cancel={JS.patch(~p"/users")}>
        <.simple_form
          :let={f}
          for={%{}}
          as={:user}
          phx-submit={JS.push("save_user") |> JS.dispatch("submit:close")}
        >
          <.fieldset legend="Create new user" text="This won't be persisted into DB, memory only">
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
            <button type="submit" class="btn btn-neutral">Save user</button>
          </:actions>
        </.simple_form>
      </.modal>
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil, doc: "Additional CSS classes to add to the modal box."
  attr :show, :boolean, default: false, doc: "Whether the modal visibility is controlled."
  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the modal is closed."
  attr :responsive, :boolean, default: false, doc: "Show at bottom on small screens."
  attr :backdrop, :boolean, default: true, doc: "Show a backdrop behind the modal."
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the modal box."

  slot :inner_block, required: true, doc: "The modal content."

  def modal(assigns) do
    ~H"""
    <dialog
      id={@id}
      class={["modal", @responsive && "modal-bottom sm:modal-middle"]}
      phx-hook="ModalHook"
      data-show={@show}
      data-cancel={@on_cancel}
    >
      <div class={["modal-box", @class]} {@rest}>
        <.focus_wrap id={"#{@id}-content"}>
          <form method="dialog">
            <button
              class="btn btn-sm btn-circle btn-ghost absolute top-2 right-2"
              aria-label={~t"close"m}
            >
              ✕
            </button>
          </form>
          <%= render_slot(@inner_block) %>
        </.focus_wrap>
      </div>
      <form :if={@backdrop} method="dialog" class="modal-backdrop">
        <button><%= ~t"close"m %></button>
      </form>
    </dialog>
    """
  end
end
