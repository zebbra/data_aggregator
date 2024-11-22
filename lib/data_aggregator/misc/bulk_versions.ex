defmodule DataAggregator.Misc.BulkVersions do
  @moduledoc """
  Bulk inserts the Versions after the action has completed.
  We apply this step manually as ash_paper_trail does not support bulk actions.
  """

  use Ash.Resource.Change

  @impl true
  def batch_change(changesets, _opts, _context) do
    changesets
  end

  @impl true
  def after_batch([{changeset, _} | _] = changesets_and_results, _opts, _context) do
    version_resource = AshPaperTrail.Resource.Info.version_resource(changeset.resource)
    version_changeset = Ash.Changeset.new(version_resource)
    actor = changeset.context[:private][:actor]
    inputs = bulk_build_notifications(changesets_and_results)

    if Enum.any?(inputs) do
      bulk_create_notifications!(changeset, version_changeset, inputs, actor)
    end

    Enum.map(changesets_and_results, fn {_, result} -> {:ok, result} end)
  end

  # defp valid_for_tracking?(%Ash.Changeset{} = changeset) do
  #   changeset.action.name not in AshPaperTrail.Resource.Info.ignore_actions(changeset.resource) &&
  #     (changeset.action_type in [:create, :destroy] ||
  #        (changeset.action_type == :update &&
  #           changeset.action.name in AshPaperTrail.Resource.Info.on_actions(changeset.resource)))
  # end

  defp bulk_build_notifications(changesets_and_results) do
    changesets_and_results
    |> Enum.filter(fn {changeset, _} ->
      changeset.action_type in [:create, :destroy] ||
        (changeset.action_type == :update && changeset.context.changed?)
    end)
    |> Enum.map(fn {changeset, result} -> build_notifications(changeset, result) end)
    |> Enum.reduce([], fn input, inputs -> [input | inputs] end)
  end

  defp bulk_create_notifications!(changeset, version_changeset, inputs, actor) do
    opts = [
      context: %{ash_paper_trail?: true},
      authorize?: authorize?(changeset.domain),
      actor: actor,
      tenant: changeset.tenant,
      domain: changeset.domain,
      skip_unknown_inputs: Enum.flat_map(inputs, &Map.keys(&1))
    ]

    Ash.bulk_create(inputs, version_changeset.resource, :create, opts)
  end

  defp build_notifications(changeset, result) do
    version_resource = AshPaperTrail.Resource.Info.version_resource(changeset.resource)

    version_resource_attributes =
      version_resource |> Ash.Resource.Info.attributes() |> Enum.map(& &1.name)

    to_skip =
      Ash.Resource.Info.primary_key(changeset.resource) ++
        AshPaperTrail.Resource.Info.ignore_attributes(changeset.resource)

    attributes_as_attributes =
      AshPaperTrail.Resource.Info.attributes_as_attributes(changeset.resource)

    change_tracking_mode = AshPaperTrail.Resource.Info.change_tracking_mode(changeset.resource)

    belongs_to_actors =
      AshPaperTrail.Resource.Info.belongs_to_actor(changeset.resource)

    actor = changeset.context[:private][:actor]

    sensitive_mode =
      changeset.context[:sensitive_attributes] ||
        AshPaperTrail.Resource.Info.sensitive_attributes(changeset.resource)

    resource_attributes =
      changeset.resource
      |> Ash.Resource.Info.attributes()
      |> Map.new(&{&1.name, &1})

    input =
      version_resource_attributes
      |> Enum.filter(&(&1 in attributes_as_attributes))
      |> Enum.reject(&(resource_attributes[&1].sensitive? and sensitive_mode != :display))
      |> Map.new(&{&1, Map.get(result, &1)})

    changes =
      resource_attributes
      |> Map.drop(to_skip)
      |> Map.values()
      |> build_changes(change_tracking_mode, changeset, result)
      |> maybe_redact_changes(resource_attributes, sensitive_mode)

    belongs_to_actors
    |> Enum.reduce(input, fn belongs_to_actor, input ->
      with true <- is_struct(actor) && actor.__struct__ == belongs_to_actor.destination,
           relationship when not is_nil(relationship) <-
             Ash.Resource.Info.relationship(version_resource, belongs_to_actor.name) do
        primary_key = Map.get(actor, hd(Ash.Resource.Info.primary_key(actor.__struct__)))
        source_attribute = Map.get(relationship, :source_attribute)
        Map.put(input, source_attribute, primary_key)
      else
        _ ->
          input
      end
    end)
    |> Map.merge(%{
      version_source_id: Map.get(result, hd(Ash.Resource.Info.primary_key(changeset.resource))),
      version_action_type: changeset.action.type,
      version_action_name: changeset.action.name,
      version_resource_identifier: AshPaperTrail.Resource.Info.resource_identifier(changeset.resource),
      changes: changes
    })
  end

  defp build_changes(attributes, :changes_only, changeset, result) do
    AshPaperTrail.ChangeBuilders.ChangesOnly.build_changes(attributes, changeset, result)
  end

  defp build_changes(attributes, :snapshot, changeset, result) do
    AshPaperTrail.ChangeBuilders.Snapshot.build_changes(attributes, changeset, result)
  end

  defp build_changes(attributes, :full_diff, changeset, result) do
    AshPaperTrail.ChangeBuilders.FullDiff.build_changes(attributes, changeset, result)
  end

  defp authorize?(domain), do: Ash.Domain.Info.authorize(domain) == :always

  defp maybe_redact_changes(changes, _, :display), do: changes

  defp maybe_redact_changes(changes, attributes, :redact) do
    attributes
    |> Map.values()
    |> Enum.filter(& &1.sensitive?)
    |> Enum.reduce(changes, fn attribute, changes ->
      Map.put(changes, attribute.name, "REDACTED")
    end)
  end

  defp maybe_redact_changes(changes, attributes, :ignore) do
    sensitive_attributes =
      attributes
      |> Map.values()
      |> Enum.filter(& &1.sensitive?)
      |> Enum.map(& &1.name)

    Map.drop(changes, sensitive_attributes)
  end
end
