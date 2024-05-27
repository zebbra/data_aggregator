defmodule Storybook.Components.Modal do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks
  alias DataAggregatorWeb.Components

  def function, do: &Components.Modal.modal/1

  def imports,
    do: [
      {Blocks.Header, [section_heading: 1]},
      {Components.Form, [simple_form: 1, fieldset: 1, fieldgroup: 1]},
      {Components.Field, [field: 1]}
    ]

  def template do
    """
    <button type="button" class="btn btn-primary" onclick="document.getElementById(':variation_id').showModal()" psb-code-hidden>
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
        id: :with_custom_width,
        attributes: %{
          backdrop: false,
          responsive: true,
          class: "max-w-3xl"
        },
        slots: [content_with_close("modal-single-with-custom-width")]
      },
      %Variation{
        id: :with_title,
        attributes: %{
          backdrop: false,
          responsive: true,
          title: "Custom title"
        },
        slots: [
          """
          <div class="bg-neutral h-20 h-screen" />
          """
        ]
      },
      %Variation{
        id: :with_title_and_custom_title_class,
        attributes: %{
          backdrop: false,
          responsive: true,
          title: "Custom title",
          title_class: "text-primary"
        },
        slots: [
          """
          <div class="bg-neutral h-20 h-screen" />
          """
        ]
      },
      %Variation{
        id: :with_header_slot,
        attributes: %{
          backdrop: false,
          responsive: true
        },
        slots: [
          """
          <:header>
            Title
          </:header>
          <div class="bg-neutral h-20 h-screen" />
          """
        ]
      },
      %Variation{
        id: :with_header_slot_and_header_and_title_class,
        attributes: %{
          backdrop: false,
          responsive: true,
          title_class: "text-primary"
        },
        slots: [
          """
          <:header>
            Title
          </:header>
          <div class="bg-neutral h-20 h-screen" />
          """
        ]
      },
      %Variation{
        id: :with_footer_slot,
        attributes: %{
          backdrop: false,
          responsive: true
        },
        slots: [
          """
          <div class="mt-8 bg-neutral h-20 h-screen" />
          <:footer>
            Footer
          </:footer>
          """
        ]
      },
      %Variation{
        id: :with_title_and_footer_slot,
        attributes: %{
          backdrop: false,
          responsive: true,
          title: "Custom title"
        },
        slots: [
          """
          <div class="bg-neutral h-20 h-screen" />
          <:footer>
            Footer
          </:footer>
          """
        ]
      },
      %Variation{
        id: :with_header_slot_and_footer_slot,
        attributes: %{
          backdrop: false,
          responsive: true
        },
        slots: [
          """
          <:header>
            Title
          </:header>
          <div class="bg-neutral h-20 h-screen" />
          <:footer>
            Footer
          </:footer>
          """
        ]
      },
      %Variation{
        id: :with_header_slot_and_footer_slot_and_close_button_position_left,
        attributes: %{
          backdrop: false,
          responsive: true,
          close_button_position: "left"
        },
        slots: [
          """
          <:header>
            Title
          </:header>
          <div class="bg-neutral h-20 h-screen" />
          <:footer>
            Footer
          </:footer>
          """
        ]
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
        id: :with_form_with_sticky_header_and_footer,
        attributes: %{
          backdrop: false,
          responsive: true,
          overflow: "manual"
        },
        slots: [
          content_with_form_with_modal("modal-single-with-form-with-sticky-header-and-footer")
        ]
      }
    ]
  end

  def content do
    """
    <.section_heading>
      Title
      <:subtitle>With a subtitle</:subtitle>
    </.section_heading>
    <div class="bg-neutral my-4 h-20" />
    """
  end

  def content_with_close(id) do
    """
    <.section_heading>
      Title
      <:subtitle>With a subtitle</:subtitle>
    </.section_heading>
    <div class="bg-neutral my-4 h-20" />
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
        <button type="submit" class="btn btn-primary">Save user</button>
        <button type="reset" class="btn btn-ghost">Reset</button>
        <button type="button" class="btn btn-ghost" onclick="document.getElementById('#{id}').close()">
          Cancel
        </button>
      </:actions>
    </.simple_form>
    """
  end

  def content_with_form_with_modal(id) do
    """
    <.simple_form
      :let={f}
      for={%{}}
      as={:user}
      phx-submit={JS.push("save_user") |> JS.dispatch("submit:close")}
      modal
    >
      <.fieldset modal legend="Create new user" text="This won't be persisted into DB, memory only.">
        <.fieldgroup modal>
          <div class="grid grid-cols-1 gap-8 sm:grid-cols-2 sm:gap-4">
            <.field field={f[:first_name_2]} label="First name" required />
            <.field field={f[:last_name_2]} label="Last name" required />
          </div>
          <div class="grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-4">
            <div class="sm:col-span-2">
              <.field field={f[:email_2]} label="EMail" type="email" required />
            </div>
            <.field field={f[:age_2]} label="Age" type="number" required />
          </div>
        </.fieldgroup>
        <:actions modal>
          <button type="submit" class="btn btn-primary">Save user</button>
          <button type="reset" class="btn btn-ghost">Reset</button>
          <button type="button" class="btn btn-ghost" onclick="document.getElementById('#{id}').close()">
            Cancel
          </button>
        </:actions>
      </.fieldset>
    </.simple_form>
    """
  end
end
