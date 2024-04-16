defmodule DataAggregatorWeb.CollectionLive.Record.Components do
  @moduledoc """
  This module contains components for the collection > record live view.
  """
  use DataAggregatorWeb, :html

  alias DataAggregator.Records
  alias DataAggregator.Records.Activity
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  require Ash.Query

  attr :state, :atom,
    required: true,
    values: [
      :not_published,
      :publishing,
      :in_publication,
      :published,
      :stale,
      :publication_failed
    ]

  def publication_status_badge(assigns) do
    case assigns.state do
      :publishing ->
        ~H"""
        <.badge class="px-2 tooltip tooltip-info" color="blue" data-tip={~t"Publication in progress"m}>
          <.icon name="hero-cog-6-tooth-solid" class="size-5 shrink-0 animate-spin" />
          <span class="text-nowrap px-1.5"><%= ~t"Publishing"m %></span>
        </.badge>
        """

      :in_publication ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-info"
          color="blue"
          data-tip={~t"Record is in the publication pipeline - no further action required"m}
        >
          <.icon name="hero-information-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"In Publication"m %></span>
        </.badge>
        """

      :published ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-success"
          color="green"
          data-tip={~t"Record was successful published"m}
        >
          <.icon name="hero-check-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Published"m %></span>
        </.badge>
        """

      :stale ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-warning"
          color="orange"
          data-tip={~t"Record was changed after publishing it and has to be republished"m}
        >
          <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Stale"m %></span>
        </.badge>
        """

      :publication_failed ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-error"
          color="red"
          data-tip={~t"Publication failed. Process should be started again"m}
        >
          <.icon name="hero-x-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Failed"m %></span>
        </.badge>
        """

      _ ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-ghost"
          color="gray"
          data-tip={~t"No publication information available. Publish the collection to see the status"m}
        >
          <.icon name="hero-question-mark-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Not Published"m %></span>
        </.badge>
        """
    end
  end

  @level [0, 1, 2, 3, 4]

  attr :level, :integer, required: true, values: @level

  def mids_level_indicator(assigns) do
    color_dot_range = Range.new(1, assigns.level)
    gray_dot_range = Range.new(1, 4 - assigns.level)

    assigns = assign(assigns, :color_dot_range, color_dot_range)
    assigns = assign(assigns, :gray_dot_range, gray_dot_range)

    ~H"""
    <div
      class={["tooltip tooltip-top flex h-8 justify-evenly rounded-full p-2", level_indicator(@level)]}
      data-tip={level_translation(@level)}
    >
      <div :for={_level <- @color_dot_range} :if={@level > 0}>
        <div class="h-4 w-4 rounded-full bg-current" />
      </div>
      <div :for={_level <- @gray_dot_range} :if={@level < 4}>
        <div class="bg-base-100 h-4 w-4 rounded-full " />
      </div>
    </div>
    """
  end

  defp level_indicator(level) do
    gray = "bg-base-300 text-base-content/60 tooltip-ghost border border-black-white/20"
    blue = "bg-info/10 text-info tooltip-info border border-info/30"
    green = "bg-success/10 text-success tooltip-success border border-success/30"
    red = "bg-error/10 text-error tooltip-error border border-error/30"
    orange = "bg-warning/10 text-warning tooltip-warning border border-warning/30"

    case level do
      4 -> green
      3 -> blue
      2 -> orange
      1 -> red
      0 -> gray
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp level_translation(level) do
    case level do
      0 ->
        ~t"Please submit at least the institution code with your data, to reach the lowest quality level"m

      1 ->
        ~t"Add all of the following fields to reach level two: taxon_id, part_of_organism"m

      2 ->
        ~t"Add the following fields to reach level three: event_date, ecorded_by, type_status, original_name_usage, continent, country, county, decimal_latitude, decimal_longitude, higher_geography, locality, state_province, verbatim_depth, verbatim_elevation, year_collection_entrance, occurrence_id"m

      3 ->
        ~t"Add one of the follwing fields to reach level four: verbatim_event_date, identified_by, identification_qualifier, identification_verification_status, last_verified_by, verbatim_identification, georeferenced_by, georeference_verification_status, verbatim_coordinates, verbatim_latitude, verbatim_longitude, verbatim_locality, associated_media, completeness, other_catalog_numbers, verbatim_label"m

      4 ->
        ~t"Record has a top quality. Add more data fields to improve your collections relevance"m
    end
  end

  attr :record, Record, required: true

  def activity_feed(assigns) do
    assigns = assign_activities(assigns)

    ~H"""
    <ul role="list" class="space-y-16 px-6">
      <li :for={activity <- @activities} class="relative flex gap-x-4">
        <div class="absolute top-0 -bottom-16 left-0 flex w-6 justify-center">
          <div class="bg-gray-100/50 w-px"></div>
        </div>
        <.activity_feed_element activity={activity} />
      </li>
    </ul>
    """
  end

  defp assign_activities(assigns) do
    assign(assigns, :record, Records.load!(assigns.record, :encoded_record, lazy?: true))

    record_versions = record_versions(assigns)
    encoded_record_versions = encoded_record_versions(assigns)

    sorted_activities =
      (record_versions ++ encoded_record_versions)
      |> activites_from_versions()
      |> sort_activities()

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
      actor: "Owner",
      date_time: version.version_inserted_at,
      content: version.changes
    }
  end

  defp record_versions(assigns) do
    Record.Version
    |> Ash.Query.for_read(:read)
    |> Ash.Query.load(:version_source)
    |> Ash.Query.filter(version_source_id == ^assigns.record.id)
    |> Ash.Query.filter(
      version_action_name in [
        :set_encoded,
        :set_encoding_failed,
        :update_approval_status,
        :update_fast_track_status,
        :import
      ]
    )
    |> DataAggregator.Records.read!()
  end

  defp encoded_record_versions(assigns) do
    encoded_record_id =
      if assigns.record.encoded_record != nil, do: assigns.record.encoded_record.id

    EncodedRecord.Version
    |> Ash.Query.for_read(:read)
    |> Ash.Query.load(:version_source)
    |> Ash.Query.filter(version_source_id == ^encoded_record_id)
    |> Ash.Query.filter(
      version_action_name in [
        :update
      ]
    )
    |> DataAggregator.Records.read!()
  end

  attr :activity, Activity, required: true

  def activity_feed_element(%{activity: activity} = assigns) when activity.name in [:import, :update] do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-2">
      <div class="bg-base-100 relative flex h-6 w-6 items-center justify-center">
        <div class="bg-base-100">
          <.activity_icon activity={@activity} />
        </div>
      </div>
      <div class="col-span-6 py-0.5 text-sm leading-5 text-gray-500">
        <span class="font-medium text-gray-600"><%= @activity.actor %></span>
        - <.activity_text activity={@activity} />
      </div>
      <div class="col-span-2 text-right">
        <time datetime={@activity.date_time} class="py-0.5 text-xs leading-5 text-gray-500">
          <%= format_datetime(@activity.date_time, format: :short) %>
        </time>
      </div>
      <div class="ring-gray-100/30 col-start-2 col-end-10 gap-2 rounded-md p-3 ring-1 hover:ring-2">
        <.changed_value :for={change <- map_to_string(@activity.content)} value={change} />
      </div>
    </div>
    """
  end

  def activity_feed_element(%{activity: activity} = assigns)
      when activity.name in [:set_encoded, :set_encoding_failed, :update_approval_status, :update_fast_track_status] do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-2 ">
      <div class="bg-base-100 relative flex h-6 w-6 items-center justify-center">
        <div class="bg-base-100 mt-2">
          <.activity_icon activity={@activity} />
        </div>
      </div>
      <div class="col-span-6 py-0.5 text-sm leading-5 text-gray-500">
        <span class="font-medium text-gray-600"><%= @activity.actor %></span>
        - <.activity_text activity={@activity} />
      </div>
      <div class="col-span-2 text-right">
        <time datetime={@activity.date_time} class="py-0.5 text-xs leading-5 text-gray-500">
          <%= format_datetime(@activity.date_time, format: :short) %>
        </time>
      </div>
    </div>
    """
  end

  # this is just the fallback for unwanted activities, which we do not want to render
  def activity_feed_element(assigns) do
    ~H"""
    <span>unknown change: <%= @activity.name %></span>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :import do
    ~H"""
    <.badge class="tooltip tooltip-info" data-tip={~t"Dataset imported"m} color="blue">
      <.icon name="hero-arrow-up-tray" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :update do
    ~H"""
    <.badge class="tooltip tooltip-success" data-tip={~t"Encoded data updated"m} color="green">
      <.icon name="hero-puzzle-piece" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :set_encoded do
    ~H"""
    <.badge class="tooltip tooltip-success" data-tip={~t"Encoding Successful"m} color="green">
      <.icon name="hero-check" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :set_encoding_failed do
    ~H"""
    <.badge class="tooltip tooltip-error" data-tip={~t"Encoding failed"m} color="red">
      <.icon name="hero-x-mark" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns)
       when activity.name in [:update_approval_status, :update_fast_track_status] do
    cond do
      published?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-success" data-tip={~t"Successful published"m} color="green">
          <.icon name="hero-check" class="size-5 shrink-0" />
        </.badge>
        """

      publishing?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-info" data-tip={~t"Publishing in progress"m} color="blue">
          <.icon name="hero-cog-6-tooth-solid" class="size-5 shrink-0" />
        </.badge>
        """

      in_publication?(activity) ->
        ~H"""
        <.badge
          class="tooltip tooltip-info"
          data-tip={~t"Record is now in the publication pipeline"m}
          color="blue"
        >
          <.icon name="hero-globe-alt" class="size-5 shrink-0" />
        </.badge>
        """

      publication_failed?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-red" data-tip={~t"Publication failed"m} color="red">
          <.icon name="hero-x-mark" class="size-5 shrink-0" />
        </.badge>
        """

      publication_stale?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-ghost" data-tip={~t"Record data changed"m} color="orange">
          <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0" />
        </.badge>
        """

      not_published?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-info" data-tip={~t"Publishing in progress"m} color="gray">
          <.icon name="hero-information-circle" class="size-5 shrink-0" />
        </.badge>
        """

      true ->
        ~H"""
        <.badge class="tooltip tooltip-info" data-tip={~t"Record is in an unknown state"m} color="gray">
          <.icon name="hero-question-mark-circle-solid" class="size-5 shrink-0" />
        </.badge>
        """
    end
  end

  defp activity_icon(assigns) do
    ~H"""
    <span>
      <%= @activity.name %> - <%= inspect(@activity.content) %>
    </span>
    """
  end

  defp activity_text(%{activity: activity} = assigns) when activity.name == :import do
    ~H"""
    <span class="font-medium">
      <%= ~t"A data import was updating the record"m %>
    </span>
    """
  end

  defp activity_text(%{activity: activity} = assigns) when activity.name == :update do
    ~H"""
    <span class="font-medium">
      <%= ~t"The record was updated by encoding"m %>
    </span>
    """
  end

  defp activity_text(%{activity: activity} = assigns) when activity.name == :set_encoded do
    ~H"""
    <span class="font-medium">
      <%= ~t"the record encoding was"m %>
    </span>
    <.badge color="green">
      <%= ~t"Successful"m %>
    </.badge>
    """
  end

  defp activity_text(%{activity: activity} = assigns) when activity.name == :set_encoding_failed do
    ~H"""
    <span class="font-medium">
      <%= ~t"the record encoding has"m %>
    </span>
    <.badge color="red">
      <%= ~t"Failed"m %>
    </.badge>
    """
  end

  defp activity_text(%{activity: activity} = assigns)
       when activity.name in [:update_approval_status, :update_fast_track_status] do
    cond do
      published?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"record was successful"m %>
        </span>
        <.badge color="green">
          <%= ~t"Published"m %>
        </.badge>
        """

      publishing?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"record is currently"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Publishing"m %>
        </.badge>
        """

      in_publication?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"record is currently"m %>
        </span>
        <.badge color="blue">
          <%= ~t"In Publication"m %>
        </.badge>
        """

      publication_failed?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"record publication"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Failed"m %>
        </.badge>
        """

      publication_stale?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"the publication is now"m %>
        </span>
        <.badge color="orange">
          <%= ~t"Stale"m %>
        </.badge>
        """

      not_published?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"record is"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Not yet Published"m %>
        </.badge>
        """

      true ->
        ~H"""
        <span class="font-medium">
          <%= ~t"record is in"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Unknown"m %>
        </.badge>
        <span class="font-medium">
          <%= ~t"state. Please re-import or encode your collection"m %>
        </span>
        """
    end
  end

  defp activity_text(assigns) do
    ~H"""
    <span>
      <%= @activity.name %> - <%= inspect(@activity.content) %>
    </span>
    """
  end

  defp published?(activity) do
    activity.content["approval_status"] == "published" or
      activity.content["fast_track_status"] == "published"
  end

  defp publishing?(activity) do
    activity.content["approval_status"] == "publishing" or
      activity.content["fast_track_status"] == "publishing"
  end

  defp in_publication?(activity) do
    activity.content["approval_status"] == "in_publication" or
      activity.content["fast_track_status"] == "in_publication"
  end

  defp publication_failed?(activity) do
    activity.content["approval_status"] == "publication_failed" or
      activity.content["fast_track_status"] == "publication_failed"
  end

  defp publication_stale?(activity) do
    activity.content["approval_status"] == "stale" or
      activity.content["fast_track_status"] == "stale"
  end

  defp not_published?(activity) do
    activity.content["approval_status"] == "not_published" or
      activity.content["fast_track_status"] == "not_published"
  end

  defp map_to_string(map) when is_map(map) do
    map
    |> stringify_values()
    |> Map.to_list()
    |> filter_nil_values()
    |> Enum.map(fn {k, v} -> {k, value_to_list(v)} end)
  end

  defp map_to_string(map) do
    inspect(map)
  end

  defp filter_nil_values(list) do
    Enum.filter(list, fn {_, v} -> v != nil end)
  end

  defp value_to_list(value) when is_map(value) do
    Map.to_list(value)
  end

  defp value_to_list(value), do: value

  defp changed_value(%{value: value} = assigns) when is_tuple(value) and tuple_size(value) == 2 do
    {key, value} = value

    assigns = assign(assigns, :key, key)
    assigns = assign(assigns, :value, value)

    cond do
      is_list(value) ->
        ~H"""
        <.changed_value :for={{k, v} <- @value} value={{k, v}} />
        """

      value == nil ->
        ~H"""
        <.badge class="tooltip tooltip-ghost" data-tip={@key} color="gray">
          <span class="italic">empty</span>
        </.badge>
        """

      true ->
        ~H"""
        <.badge class="tooltip tooltip-ghost" data-tip={@key} color="gray">
          <%= @value %>
        </.badge>
        """
    end
  end

  defp stringify_values(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      updated_value =
        case value do
          v when v == %{} -> nil
          v when is_map(v) -> stringify_values(v)
          v -> v
        end

      Map.put(acc, key, updated_value)
    end)
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Record.Components
    end
  end
end
