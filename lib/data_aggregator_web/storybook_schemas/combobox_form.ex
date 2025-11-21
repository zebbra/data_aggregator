defmodule DataAggregatorWeb.StorybookSchemas.ComboboxForm do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :assignee, :string
    field :users, {:array, :string}
  end

  def changeset(%__MODULE__{} = form, params \\ %{}) do
    form
    |> cast(params, [:assignee])
    |> cast(params, [:users])
    |> validate_required([:assignee])
    |> validate_required([:users])
  end
end
