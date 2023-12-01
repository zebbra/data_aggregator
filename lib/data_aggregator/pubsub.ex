defmodule DataAggregator.PubSub do
  @moduledoc """
  A PubSub server that uses Phoenix.PubSub to broadcast messages to all
  subscribers.
  """

  @name __MODULE__

  require Logger

  @doc """
  Allows using this module directly as supervisor child
  """
  def child_spec([]) do
    Phoenix.PubSub.child_spec(name: @name)
  end

  def broadcast(topic, event, notification) do
    %Ash.Notifier.Notification{resource: resource} = notification
    resource_name = resource |> to_string() |> String.replace_prefix("Elixir.", "")

    topic |> log("#{resource_name}:#{event}")

    message = {topic, event, notification}
    Phoenix.PubSub.broadcast(@name, topic, message)
  end

  def subscribe(topic) when is_binary(topic) do
    topic |> log("subscribed")
    Phoenix.PubSub.subscribe(@name, topic)
  end

  def subscribe(topics) when is_list(topics) do
    Enum.each(topics, &subscribe/1)
  end

  def unsubscribe(topic) when is_binary(topic) do
    topic |> log("unsubscribed")
    Phoenix.PubSub.unsubscribe(@name, topic)
  end

  def unsubscribe(topics) when is_list(topics) do
    Enum.each(topics, &unsubscribe/1)
  end

  def broadcast(topic, message) when is_binary(topic) do
    topic |> log("broadcast")
    Phoenix.PubSub.broadcast(@name, topic, message)
  end

  defp log(topic, message) do
    [:blue, "[PubSub] ", :reset, message, " -> ", :faint, topic]
    |> IO.ANSI.format()
    |> Logger.info()
  end
end
