defmodule DataAggregator.Platform.Changes.ImportRecord do
  @moduledoc """
  Map file columns to record params
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.Import.Column

  def change(%Changeset{} = changeset, _opts, _ctx) do
    columns = Changeset.get_data(changeset, :columns)
    collection = Changeset.get_data(changeset, :collection)

    params =
      changeset
      |> Changeset.get_argument(:params)
      |> map_params(columns)

    changeset
    |> Changeset.manage_relationship(
      :records,
      [%{params: params, collection: collection}],
      use_identities: [:_primary_key, :mte_material_entity_id],
      # on_match: {:update, :update_from_params},
      # on_match: :error,
      # on_lookup: :relate,
      on_no_match: {:create, :create_from_params}
    )
  end

  def map_params(params, columns) do
    for {name, value} <- params, into: %{} do
      {map_param_name(columns, name), value}
    end
  end

  def map_param_name(columns, name) do
    case get_column(columns, name) do
      %Column{mapped_to: nil} -> name
      %Column{mapped_to: mapped_to} -> mapped_to
    end
  end

  def get_column(columns, name) do
    Enum.find(columns, &(&1.name == name))
  end
end
