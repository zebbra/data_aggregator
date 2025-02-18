defmodule DataAggregatorWeb.CollectionLive.Record.ActivityFeed do
  @moduledoc false
  use DataAggregatorWeb, :html

  import DataAggregatorWeb.CollectionLive.Record.Components,
    only: [publication_state_badge: 1, validation_state_badge: 1]

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [get_dwc_field: 1]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Activity
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  require Ash.Query

  attr :record, Record, required: true
  attr :tenant, Collection, required: true

  def activity_feed(assigns) do
    assigns = assign_activities(assigns)

    ~H"""
    <ul role="list" class="space-y-16 overflow-y-hidden p-6">
      <li :for={activity <- @activities} class="relative flex gap-x-4">
        <div class="absolute top-0 -bottom-16 left-0 flex w-6 justify-center">
          <div class="bg-black-white/10 w-px"></div>
        </div>
        <.activity_feed_element activity={activity} />
      </li>
    </ul>
    """
  end

  attr :activity, Activity, required: true

  def activity_feed_element(%{activity: activity} = assigns) when activity.name in [:import, :update, :add_image_url] do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-4">
      <div class="bg-base-100 size-6 relative flex items-center justify-center">
        <div class="bg-base-100">
          <.activity_icon activity={@activity} />
        </div>
      </div>
      <div class="text-sm/5 text-base-content/60 col-span-6 py-0.5">
        <span class="text-base-content font-medium">{@activity.actor}</span>
        - <.activity_text activity={@activity} />
      </div>
      <div class="col-span-2 text-right">
        <time datetime={@activity.date_time} class="text-xs/5 text-base-content/60 py-0.5">
          {format_datetime(@activity.date_time, format: :short)}
        </time>
      </div>
      <div class="indicator col-start-2 col-end-10 w-auto">
        <span class="indicator-item end-2 badge badge-primary badge-sm translate-x-0">
          {@activity.source}
        </span>
        <div class="ring-base-content/20 w-full rounded-md pt-5 pb-4 ring-1">
          <.table
            id={"table_#{@activity.index}"}
            opts={[
              container_attrs: [class: "overflow-x-auto no-scrollbar"]
            ]}
            items={Enum.map(@activity.content, fn {k, v} -> %{attr: k, value: v} end)}
          >
            <:col :let={change} label={~t"Attribute"} class="font-semibold">
              {get_dwc_field(change.attr)}
            </:col>
            <:col :let={change} label={~t"Value"}>
              <.publication_state_badge
                :if={change.attr == "fast_track_status"}
                state={String.to_existing_atom(change.value)}
              />
              <.validation_state_badge
                :if={change.attr == "validation_status"}
                state={String.to_existing_atom(change.value)}
              />
              <%= if change.attr not in ~w(validation_status fast_track_status) do %>
                {inspect(change.value)}
              <% end %>
            </:col>
          </.table>
        </div>
      </div>
    </div>
    """
  end

  def activity_feed_element(%{activity: activity} = assigns)
      when activity.name in [:set_encoded, :set_encoding_failed, :update_validation_status, :update_fast_track_status] do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-2 ">
      <div class="bg-base-100 size-6 relative flex items-center justify-center">
        <div class="bg-base-100 mt-2">
          <.activity_icon activity={@activity} />
        </div>
      </div>
      <div class="text-sm/5 text-base-content/60 col-span-6 py-0.5">
        <span class="text-base-content font-medium">{@activity.actor}</span>
        - <.activity_text activity={@activity} />
      </div>
      <div class="col-span-2 text-right">
        <time datetime={@activity.date_time} class="text-xs/5 text-base-content/60 py-0.5">
          {format_datetime(@activity.date_time, format: :short)}
        </time>
      </div>
    </div>
    """
  end

  # this is just the fallback for unwanted activities, which we do not want to render
  def activity_feed_element(assigns) do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-4">
      <div class="bg-base-100 size-6 relative flex items-center justify-center">
        <div class="bg-base-100">
          <.activity_icon />
        </div>
      </div>
      <div class="text-sm/5 text-base-content/60 col-span-6 py-0.5">
        <span class="text-base-content font-medium">{@activity.actor}</span>
        - <span>unknown change: {@activity.name}</span>
      </div>
    </div>
    """
  end

  defp activity_icon(%{activity: activity} = assigns)
       when activity.name in [
              :import,
              :update,
              :set_encoded,
              :set_encoding_failed,
              :update_validation_status,
              :update_fast_track_status,
              :add_image_url
            ] do
    ~H"""
    <.badge
      class="tooltip tooltip-right"
      data-tip={icon_tooltip(@activity.name, @activity.content)}
      color={badge_color(@activity.name, @activity.content)}
    >
      <.icon name={icon_lookup(@activity.name, @activity.content)} class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: _activity} = assigns) do
    ~H"""
    <span>
      {@activity.name} - {inspect(@activity.content)}
    </span>
    """
  end

  defp activity_icon(assigns) do
    ~H"""
    <.badge class="tooltip tooltip-right" data-tip={~t"Unknown activity"m} color="gray">
      <.icon name="hero-question-mark-circle-solid" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_text(%{activity: activity} = assigns) when activity.name in [:import, :update, :add_image_url] do
    ~H"""
    <span class="font-medium">
      {text(@activity.name, @activity.content)}
    </span>
    """
  end

  defp activity_text(%{activity: activity} = assigns)
       when activity.name in [:set_encoded, :set_encoding_failed, :update_validation_status, :update_fast_track_status] do
    ~H"""
    <span class="font-medium">
      {text(@activity.name, @activity.content)}
    </span>
    <.badge
      :if={badge_text(@activity.name, @activity.content)}
      color={badge_color(@activity.name, @activity.content)}
    >
      {badge_text(@activity.name, @activity.content)}
    </.badge>
    """
  end

  defp activity_text(assigns) do
    ~H"""
    <span>
      {@activity.name} - {inspect(@activity.content)}
    </span>
    """
  end

  defp assign_activities(assigns) do
    %{tenant: tenant, record: record} = assigns

    record =
      case record.encoded_record do
        %Ash.NotLoaded{} ->
          %{record | encoded_record: EncodedRecord.get_by_record!(record.id, tenant: tenant)}

        _ ->
          record
      end

    assign(assigns, :record, record)

    record_versions = record_versions(assigns)
    encoded_record_versions = encoded_record_versions(assigns)

    sorted_activities =
      (record_versions ++ encoded_record_versions)
      |> activites_from_versions()
      |> sort_activities()
      |> Enum.with_index(fn activity, index -> Map.put(activity, :index, index) end)

    assign(assigns, :activities, sorted_activities)
  end

  defp sort_activities(activities) do
    Enum.sort_by(activities, & &1.date_time, {:desc, DateTime})
  end

  defp activites_from_versions(versions) do
    Enum.map(versions, &version_to_activity/1)
  end

  defp version_to_activity(version) do
    %Activity{
      name: version.version_action_name,
      actor: maybe_set_actor(version.user),
      date_time: version.version_inserted_at,
      content: version.changes,
      source: version_source(version)
    }
  end

  defp maybe_set_actor(%User{first_name: first_name, last_name: last_name}) when first_name != nil and last_name != nil,
    do: "#{first_name} #{last_name}"

  defp maybe_set_actor(%User{email: email}) when email != nil, do: email
  defp maybe_set_actor(%User{}), do: ~t"Anonym"m
  defp maybe_set_actor(_), do: ~t"System"m

  defp version_source(%{version_action_name: :update_fast_track_status}), do: ~t"Publication"
  defp version_source(%{version_action_name: :update_validation_status}), do: ~t"Validation"
  defp version_source(%{version_action_name: :import}), do: ~t"Import"

  defp version_source(%{version_action_name: :update} = version), do: version_source_from_catalog(version.changes)

  defp version_source(%{version_action_name: :add_image_url}), do: ~t"Image Upload"

  defp version_source(_), do: nil

  defp version_source_from_catalog(%{} = changes) when changes == %{}, do: ~t"Unknown"

  defp version_source_from_catalog(%{} = changes) do
    keys =
      changes
      |> Map.keys()
      |> Enum.map(&String.to_existing_atom/1)

    catalogs = Catalog.get_catalogs()

    catalog_name =
      Enum.reduce_while(catalogs, nil, fn catalog, _ ->
        catalog_output_dwc_attributes = Catalog.get_output_dwc_attributes(catalog)

        if Enum.all?(keys, &Enum.member?(catalog_output_dwc_attributes, &1)) do
          {:halt, catalog}
        else
          {:cont, nil}
        end
      end)

    Catalog.translate_catalog(catalog_name)
  end

  defp record_versions(assigns) do
    Record.Version
    |> Ash.Query.for_read(:read)
    |> Ash.Query.load([:version_source, :user])
    |> Ash.Query.set_tenant(assigns.tenant)
    |> Ash.Query.filter(version_source_id == ^assigns.record.id)
    |> Ash.read!()
  end

  defp encoded_record_versions(assigns) do
    encoded_record_id =
      if assigns.record.encoded_record != nil, do: assigns.record.encoded_record.id

    EncodedRecord.Version
    |> Ash.Query.for_read(:read)
    |> Ash.Query.load([:version_source, :user])
    |> Ash.Query.set_tenant(assigns.tenant)
    |> Ash.Query.filter(version_source_id == ^encoded_record_id)
    |> Ash.read!()
  end

  def icon_lookup(:import, _), do: "hero-arrow-up-tray"
  def icon_lookup(:update, _), do: "hero-puzzle-piece"
  def icon_lookup(:set_encoded, _), do: "hero-check"
  def icon_lookup(:set_encoding_failed, _), do: "hero-x-mark"

  def icon_lookup(:update_fast_track_status, content) do
    case content["fast_track_status"] do
      "not_published" -> "hero-question-mark-circle"
      "publishing" -> "hero-cog-6-tooth-solid"
      "in_publication" -> "hero-globe-alt"
      "published" -> "hero-check"
      "publication_failed" -> "hero-x-mark"
      "stale" -> "hero-exclamation-triangle-solid"
      _ -> "hero-globe-alt"
    end
  end

  def icon_lookup(:update_validation_status, content) do
    case content["validation_status"] do
      "not_validated" -> "hero-question-mark-circle"
      "validating" -> "hero-cog-6-tooth-solid"
      "in_validation" -> "hero-check-badge"
      "validated" -> "hero-check"
      "validation_failed" -> "hero-x-mark"
      "stale" -> "hero-exclamation-triangle-solid"
      _ -> "hero-check-badge"
    end
  end

  def icon_lookup(:add_image_url, _), do: "hero-photo"

  def icon_lookup(_, _), do: "hero-question-mark-circle-solid"

  def icon_tooltip(:import, _), do: ~t"Dataset imported"m
  def icon_tooltip(:update, _), do: ~t"Encoded data updated"m
  def icon_tooltip(:set_encoded, _), do: ~t"Encoding successful"m
  def icon_tooltip(:set_encoding_failed, _), do: ~t"Encoding failed"m

  def icon_tooltip(:update_fast_track_status, content) do
    case content["fast_track_status"] do
      "not_published" ->
        ~t"No publication information available. Publish the dataset to see the status"m

      "publishing" ->
        ~t"Publication in progress"m

      "in_publication" ->
        ~t"Record is now in the publication pipeline - no further action required"m

      "published" ->
        ~t"Record publication was successful"m

      "publication_failed" ->
        ~t"Publication failed. Process should be started again"m

      "stale" ->
        ~t"Record was changed after publishing it and has to be republished"m

      _ ->
        nil
    end
  end

  def icon_tooltip(:update_validation_status, content) do
    case content["validation_status"] do
      "not_validated" ->
        ~t"No validation information available. Validate the dataset to see the status"m

      "validating" ->
        ~t"Validation in progress"m

      "in_validation" ->
        ~t"Record is now in the validation pipeline - no further action required"m

      "validated" ->
        ~t"Record validation was successful"m

      "validation_failed" ->
        ~t"Validation failed. Process should be started again"m

      "stale" ->
        ~t"Record data changed after validating it and has to be revalidated"m

      _ ->
        nil
    end
  end

  def icon_tooltip(:add_image_url, _), do: ~t"associatedMedia was updated"m

  def icon_tooltip(_, _), do: nil

  defp text(:import, _), do: ~t"A data import was updating the record"m
  defp text(:update, _), do: ~t"The record was updated by encoding"m
  defp text(:set_encoded, _), do: ~t"The record encoding was"m
  defp text(:set_encoding_failed, _), do: ~t"The record encoding has"m

  defp text(:update_fast_track_status, content) do
    case content["fast_track_status"] do
      "not_published" -> ~t"Record is"m
      "publishing" -> ~t"Record is currently"m
      "in_publication" -> ~t"Record is now"m
      "published" -> ~t"Record was successful"m
      "publication_failed" -> ~t"Record publication"m
      "stale" -> ~t"The publication is now"m
      _ -> ~t"Publication status was updated"m
    end
  end

  defp text(:update_validation_status, content) do
    case content["validation_status"] do
      "not_validated" -> ~t"Record is"m
      "validating" -> ~t"Record is currently"m
      "in_validation" -> ~t"Record is now"m
      "validated" -> ~t"Record was successful"m
      "validation_failed" -> ~t"Record validation"m
      "stale" -> ~t"The validation is now"m
      _ -> ~t"Validation status was updated"m
    end
  end

  defp text(:add_image_url, _), do: ~t"associatedMedia was updated"m

  defp text(name, _), do: name

  def badge_text(:set_encoded, _), do: ~t"Successful"m
  def badge_text(:set_encoding_failed, _), do: ~t"Failed"m

  def badge_text(:update_fast_track_status, content) do
    case content["fast_track_status"] do
      "not_published" -> ~t"Not Published"m
      "publishing" -> ~t"Publishing"m
      "in_publication" -> ~t"In Publication"m
      "published" -> ~t"Published"m
      "publication_failed" -> ~t"Failed"m
      "stale" -> ~t"Stale"m
      _ -> nil
    end
  end

  def badge_text(:update_validation_status, content) do
    case content["validation_status"] do
      "not_validated" -> ~t"Not Validated"m
      "validating" -> ~t"Validating"m
      "in_validation" -> ~t"In Validation"m
      "validated" -> ~t"Validated"m
      "validation_failed" -> ~t"Failed"m
      "stale" -> ~t"Stale"m
      _ -> nil
    end
  end

  def badge_text(_, _), do: nil

  def badge_color(:import, _), do: "blue"
  def badge_color(:update, _), do: "green"
  def badge_color(:set_encoded, _), do: "green"
  def badge_color(:set_encoding_failed, _), do: "red"

  def badge_color(:update_fast_track_status, content) do
    case content["fast_track_status"] do
      "not_published" -> "gray"
      "publishing" -> "blue"
      "in_publication" -> "blue"
      "published" -> "green"
      "publication_failed" -> "red"
      "stale" -> "orange"
      _ -> "green"
    end
  end

  def badge_color(:update_validation_status, content) do
    case content["validation_status"] do
      "not_validated" -> "gray"
      "validating" -> "blue"
      "in_validation" -> "blue"
      "validated" -> "green"
      "validation_failed" -> "red"
      "stale" -> "orange"
      _ -> "green"
    end
  end

  def badge_color(:add_image_url, _), do: "green"

  def badge_color(_, _), do: "gray"
end
