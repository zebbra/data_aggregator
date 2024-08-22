defmodule DataAggregator.Accounts.UserImporter do
  @moduledoc """
  Import users from csv file
  """

  alias DataAggregator.Accounts.User

  require Logger

  def import_users_from_csv(path) do
    path
    |> Path.expand()
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.each(&maybe_import_user_from_csv/1)
  end

  defp maybe_import_user_from_csv(attrs) do
    parsed_attrs = parse_csv_attributes(attrs)

    case User.get_by_email(parsed_attrs["email"]) do
      {:error, _} ->
        User.register_with_password!(parsed_attrs)
        Logger.info("importing user: #{inspect(parsed_attrs)}")

      {:ok, _} ->
        Logger.info("user already exists: #{inspect(parsed_attrs)}")
    end
  rescue
    error ->
      Logger.error("could not import user: #{inspect(attrs)}, reason was: #{inspect(error)}")

      throw(error)
  end

  defp parse_csv_attributes(attrs) do
    Map.new(attrs, &parse_attribute/1)
  end

  defp parse_attribute({"roles", value}) when is_binary(value) do
    {"roles", [value]}
  end

  defp parse_attribute({"roles", value}) when is_list(value) do
    {"roles", value}
  end

  defp parse_attribute(attribute), do: attribute
end
