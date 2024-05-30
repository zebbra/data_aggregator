defmodule DataAggregatorWeb.CollectionLive.Record.ActivityFeed do
  @moduledoc false
  use DataAggregatorWeb, :html

  alias DataAggregator.Records
  alias DataAggregator.Records.Activity
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  require Ash.Query

  attr :record, Record, required: true

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

  defp activity_feed_element(%{activity: activity} = assigns) when activity.name in [:import, :update] do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-2">
      <div class="bg-base-100 size-6 relative flex items-center justify-center">
        <div class="bg-base-100">
          <.activity_icon activity={@activity} />
        </div>
      </div>
      <div class="text-sm/5 col-span-6 py-0.5 text-gray-500">
        <span class="font-medium text-gray-600"><%= @activity.actor %></span>
        - <.activity_text activity={@activity} />
      </div>
      <div class="col-span-2 text-right">
        <time datetime={@activity.date_time} class="text-xs/5 py-0.5 text-gray-500">
          <%= format_datetime(@activity.date_time, format: :short) %>
        </time>
      </div>
      <div class="ring-gray-100/30 col-start-2 col-end-10 rounded-md pt-3 pr-2 pb-2 pl-3 ring-1 hover:ring-2">
        <.changed_value :for={change <- map_to_string(@activity.content)} value={change} />
      </div>
    </div>
    """
  end

  defp activity_feed_element(%{activity: activity} = assigns)
       when activity.name in [:set_encoded, :set_encoding_failed, :update_approval_status, :update_fast_track_status] do
    ~H"""
    <div class="grid w-full grid-cols-9 gap-y-2 ">
      <div class="bg-base-100 size-6 relative flex items-center justify-center">
        <div class="bg-base-100 mt-2">
          <.activity_icon activity={@activity} />
        </div>
      </div>
      <div class="text-sm/5 col-span-6 py-0.5 text-gray-500">
        <span class="font-medium text-gray-600"><%= @activity.actor %></span>
        - <.activity_text activity={@activity} />
      </div>
      <div class="col-span-2 text-right">
        <time datetime={@activity.date_time} class="text-xs/5 py-0.5 text-gray-500">
          <%= format_datetime(@activity.date_time, format: :short) %>
        </time>
      </div>
    </div>
    """
  end

  # this is just the fallback for unwanted activities, which we do not want to render
  defp activity_feed_element(assigns) do
    ~H"""
    <span>unknown change: <%= @activity.name %></span>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :import do
    ~H"""
    <.badge class="tooltip tooltip-right" data-tip={~t"Dataset imported"m} color="blue">
      <.icon name="hero-arrow-up-tray" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :update do
    ~H"""
    <.badge class="tooltip tooltip-right" data-tip={~t"Encoded data updated"m} color="green">
      <.icon name="hero-puzzle-piece" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :set_encoded do
    ~H"""
    <.badge class="tooltip tooltip-right" data-tip={~t"Encoding Successful"m} color="green">
      <.icon name="hero-check" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns) when activity.name == :set_encoding_failed do
    ~H"""
    <.badge class="tooltip tooltip-right" data-tip={~t"Encoding failed"m} color="red">
      <.icon name="hero-x-mark" class="size-5 shrink-0" />
    </.badge>
    """
  end

  defp activity_icon(%{activity: activity} = assigns)
       when activity.name in [:update_approval_status, :update_fast_track_status] do
    cond do
      published?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-right" data-tip={~t"Successful published"m} color="green">
          <.icon name="hero-check" class="size-5 shrink-0" />
        </.badge>
        """

      publishing?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-right" data-tip={~t"Publishing in progress"m} color="blue">
          <.icon name="hero-cog-6-tooth-solid" class="size-5 shrink-0" />
        </.badge>
        """

      in_publication?(activity) ->
        ~H"""
        <.badge
          class="tooltip tooltip-right"
          data-tip={~t"Record is now in the publication pipeline"m}
          color="blue"
        >
          <.icon name="hero-globe-alt" class="size-5 shrink-0" />
        </.badge>
        """

      publication_failed?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-right" data-tip={~t"Publication failed"m} color="red">
          <.icon name="hero-x-mark" class="size-5 shrink-0" />
        </.badge>
        """

      publication_stale?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-right" data-tip={~t"Record data changed"m} color="orange">
          <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0" />
        </.badge>
        """

      not_published?(activity) ->
        ~H"""
        <.badge class="tooltip tooltip-right" data-tip={~t"Publishing in progress"m} color="blue">
          <.icon name="hero-information-circle" class="size-5 shrink-0" />
        </.badge>
        """

      true ->
        ~H"""
        <.badge class="tooltip tooltip-right" data-tip={~t"Record is in an unknown state"m} color="blue">
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
      <%= ~t"The record encoding was"m %>
    </span>
    <.badge color="green">
      <%= ~t"Successful"m %>
    </.badge>
    """
  end

  defp activity_text(%{activity: activity} = assigns) when activity.name == :set_encoding_failed do
    ~H"""
    <span class="font-medium">
      <%= ~t"The record encoding has"m %>
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
          <%= ~t"Record was successful"m %>
        </span>
        <.badge color="green">
          <%= ~t"Published"m %>
        </.badge>
        """

      publishing?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"Record is currently"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Publishing"m %>
        </.badge>
        """

      in_publication?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"Record is currently"m %>
        </span>
        <.badge color="blue">
          <%= ~t"In Publication"m %>
        </.badge>
        """

      publication_failed?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"Record publication"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Failed"m %>
        </.badge>
        """

      publication_stale?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"The publication is now"m %>
        </span>
        <.badge color="orange">
          <%= ~t"Stale"m %>
        </.badge>
        """

      not_published?(activity) ->
        ~H"""
        <span class="font-medium">
          <%= ~t"Record is"m %>
        </span>
        <.badge color="blue">
          <%= ~t"Not yet Published"m %>
        </.badge>
        """

      true ->
        ~H"""
        <span class="font-medium">
          <%= ~t"Record is in"m %>
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
    |> Records.read!()
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
    |> Records.read!()
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

    if is_list(value) do
      ~H"""
      <.changed_value :for={{k, v} <- @value} value={{k, v}} />
      """
    else
      ~H"""
      <.badge class="tooltip mr-1 mb-1" data-tip={@key} color="gray">
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
      import DataAggregatorWeb.CollectionLive.Record.ActivityFeed
    end
  end
end
