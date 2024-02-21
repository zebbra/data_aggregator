defmodule Storybook.Components.Alert do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Alert.alert/1

  def imports,
    do: [
      {Components.Form, [simple_form: 1, fieldset: 1, fieldgroup: 1]},
      {Components.Field, [field: 1]}
    ]

  def template do
    """
    <button type="button" class="btn btn-neutral" onclick="document.getElementById(':variation_id').showModal()" psb-code-hidden>
      Open alert
    </button>
    <.psb-variation/>
    """
  end

  def variations do
    [
      %Variation{
        id: :default
      },
      %Variation{
        id: :with_with_callbacks,
        attributes: %{
          on_cancel: JS.dispatch("storybook:console:log"),
          on_confirm: JS.dispatch("storybook:console:log")
        }
      },
      %Variation{
        id: :with_title,
        attributes: %{
          title: "This is an alert"
        }
      },
      %Variation{
        id: :with_text,
        attributes: %{
          text: "This is an alert"
        }
      },
      %Variation{
        id: :with_form,
        attributes: %{
          form: true,
          on_confirm: JS.dispatch("storybook:console:log")
        },
        slots: [render_form("alert-single-with-form")]
      },
      %Variation{
        id: :size_xs,
        attributes: %{
          size: "xs"
        }
      },
      %Variation{
        id: :size_sm,
        attributes: %{
          size: "sm"
        }
      },
      %Variation{
        id: :size_md,
        attributes: %{
          size: "md"
        }
      },
      %Variation{
        id: :size_lg,
        attributes: %{
          size: "lg"
        }
      },
      %Variation{
        id: :size_xl,
        attributes: %{
          size: "xl"
        }
      },
      %Variation{
        id: :size_2xl,
        attributes: %{
          size: "2xl"
        }
      },
      %Variation{
        id: :size_3xl,
        attributes: %{
          size: "3xl"
        }
      },
      %Variation{
        id: :size_4xl,
        attributes: %{
          size: "4xl"
        }
      },
      %Variation{
        id: :size_5xl,
        attributes: %{
          size: "5xl"
        }
      }
    ]
  end

  defp render_form(id) do
    """
    <.simple_form
      :let={f}
      for={%{}}
      as={:user}
      phx-submit={JS.dispatch("submit:close")}
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
        <button type="button" class="btn btn-ghost" onclick="document.getElementById('#{id}').close()">
          Cancel
        </button>
        <button type="reset" class="btn btn-ghost">Reset</button>
        <button type="submit" class="btn btn-neutral">Save user</button>
      </:actions>
    </.simple_form>
    """
  end
end
