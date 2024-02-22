defmodule Storybook.Components.Modal do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Blocks
  alias DataAggregatorWeb.Components

  def function, do: &Components.Modal.modal/1

  def imports,
    do: [
      {Blocks.Header, [header: 1]},
      {Components.Form, [simple_form: 1, fieldset: 1, fieldgroup: 1]},
      {Components.Field, [field: 1]}
    ]

  def template do
    """
    <button type="button" class="btn btn-neutral" onclick="document.getElementById(':variation_id').showModal()" psb-code-hidden>
      Open modal
    </button>
    <.psb-variation/>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        slots: [content()]
      },
      %Variation{
        id: :no_backdrop,
        attributes: %{
          backdrop: false
        },
        slots: [content()]
      },
      %Variation{
        id: :responsive,
        attributes: %{
          responsive: true
        },
        slots: [content()]
      },
      %Variation{
        id: :with_close_button,
        attributes: %{
          responsive: true
        },
        slots: [content_with_close("modal-single-with-close-button")]
      },
      %Variation{
        id: :with_on_cancel,
        attributes: %{
          responsive: true,
          on_cancel: JS.dispatch("storybook:console:log")
        },
        slots: [content_with_close("modal-single-with-on-cancel")]
      },
      %Variation{
        id: :with_form,
        attributes: %{
          backdrop: false,
          responsive: true
        },
        slots: [content_with_form("modal-single-with-form")]
      },
      %Variation{
        id: :with_custom_width,
        attributes: %{
          backdrop: false,
          responsive: true,
          class: "max-w-3xl"
        },
        slots: [content_with_close("modal-single-with-custom-width")]
      }
    ]
  end

  def content do
    """
    <.header>
      Title
      <:subtitle>With a subtitle</:subtitle>
    </.header>
    """
  end

  def content_with_close(id) do
    """
    <.header>
      Title
      <:subtitle>With a subtitle</:subtitle>
    </.header>
    <div class="modal-action">
      <button type="button" class="btn btn-ghost" onclick="getElementById('#{id}').close()">
        Close
      </button>
    </div>
    """
  end

  def content_with_form(id) do
    """
    <.simple_form
      :let={f}
      for={%{}}
      as={:user}
      phx-submit={JS.push("save_user") |> JS.dispatch("submit:close")}
    >
      <.fieldset legend="Create new user" text="This won't be persisted into DB, memory only.">
        <.fieldgroup>
          <div class="grid grid-cols-1 gap-8 sm:grid-cols-2 sm:gap-4">
            <.field field={f[:first_name]} label="First name" required />
            <.field field={f[:last_name]} label="Last name" required />
          </div>
          <div class="grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-4">
            <div class="sm:col-span-2">
              <.field field={f[:email]} label="EMail" type="email" required />
            </div>
            <.field field={f[:age]} label="Age" type="number" required />
          </div>
        </.fieldgroup>
      </.fieldset>

      <:actions>
        <button type="submit" class="btn btn-neutral">Save user</button>
        <button type="reset" class="btn btn-ghost">Reset</button>
        <button type="button" class="btn btn-ghost" onclick="document.getElementById('#{id}').close()">
          Cancel
        </button>
      </:actions>
    </.simple_form>
    """
  end
end
