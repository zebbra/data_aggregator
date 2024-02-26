defmodule DataAggregatorWeb.Components.Modal do
  @moduledoc """
  Modal components.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm_modal">
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
  to push the submit:close event on successfull form submit to the client. This event
  is handled in the dialog.hook.ts DialogHook and will manually close the dialog. If you
  control the modal with the :if directive combined with the show attr, you do not need
  to push this event.

  For example:

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
  """
  attr(:id, :string, required: true)
  attr(:class, :string, default: nil, doc: "Additional CSS classes to add to the modal box.")
  attr(:show, :boolean, default: false, doc: "Whether the modal visibility is controlled.")
  attr(:on_cancel, JS, default: %JS{}, doc: "JS commands to run when the modal is closed.")
  attr(:responsive, :boolean, default: false, doc: "Show at bottom on small screens.")
  attr(:backdrop, :boolean, default: true, doc: "Show a backdrop behind the modal.")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the modal box.")

  attr(:size, :string,
    values: ["xs", "sm", "md", "lg", "xl", "2xl", "3xl", "4xl", "5xl", nil],
    default: nil
  )

  slot(:inner_block, required: true, doc: "The modal content.")

  def modal(assigns) do
    ~H"""
    <dialog
      id={@id}
      class={["modal", @responsive && "modal-bottom sm:modal-middle"]}
      phx-hook="DialogHook"
      data-show={@show}
      data-cancel={@on_cancel}
    >
      <div class={["modal-box max-h-[calc(100dvh-5em)]", @class, size(@size)]} {@rest}>
        <.focus_wrap id={"#{@id}_content"}>
          <%= render_slot(@inner_block) %>
          <form method="dialog">
            <button
              class="btn btn-sm btn-circle btn-ghost absolute top-2 right-2"
              aria-label={~t"close"m}
            >
              <.icon name="hero-x-mark-mini" class="text-base-content/75" />
            </button>
          </form>
        </.focus_wrap>
      </div>
      <form :if={@backdrop} method="dialog" class="modal-backdrop">
        <button><%= ~t"close"m %></button>
      </form>
    </dialog>
    """
  end

  defp size(nil), do: ""

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp size(size) do
    case String.to_atom(size) do
      :xs -> "sm:max-w-xs"
      :sm -> "sm:max-w-sm"
      :md -> "sm:max-w-md"
      :lg -> "sm:max-w-lg"
      :xl -> "sm:max-w-xl"
      :"2xl" -> "sm:max-w-2xl"
      :"3xl" -> "sm:max-w-3xl"
      :"4xl" -> "sm:max-w-4xl"
      :"5xl" -> "sm:max-w-5xl"
      _ -> "sm:max-w-5xl"
    end
  end
end
