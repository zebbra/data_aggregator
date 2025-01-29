defmodule DataAggregator.Misc.FlatFileUtils do
  @moduledoc """
  Utility functions for working with CSV files
  """
  alias DataAggregator.Files.Attachment

  @doc """
  gives you a map of all relevant header fields and the record values
  in the structure of `%{"verbatimLocality" => nil, "kingdom" => "My Kingdom", ..}`

  ## Transforming the data

  If you want to transform the data before mapping it to the headers, you can pass a
  map of transformers to the function. The transformers map should have the same keys
  as the header_fields map and the values should be functions that take the record
  value as an argument and return the transformed value.

  ### Example:

  ```elixir
  header_fields = %{
    "verbatimLocality" => "Verbatim Locality",
    "kingdom" => "Kingdom"
  }

  transformers = %{
    "kingdom" => fn value -> String.upcase(value) end
  }

  map_data_to_headers(record_data, header_fields, transformers)
  ```
  """
  @spec map_data_to_headers(map(), list(), map() | nil) :: map()
  def map_data_to_headers(record_data, header_fields, transformers \\ nil)

  def map_data_to_headers(record_data, header_fields, nil) do
    Map.new(header_fields, fn {k, v} ->
      {v, maybe_from_extra_data(record_data, k)}
    end)
  end

  def map_data_to_headers(record_data, header_fields, transformers) do
    Map.new(header_fields, fn {k, v} ->
      if Map.has_key?(transformers, k) do
        {v,
         record_data
         |> maybe_from_extra_data(k)
         |> transformers[k].()}
      else
        {v, maybe_from_extra_data(record_data, k)}
      end
    end)
  end

  @doc """
  Same as `map_data_to_headers/3`, but returns a list of values instead of a map
  """
  @spec map_data_to_headers_list(map(), list(), map() | nil) :: list()
  def map_data_to_headers_list(record_data, header_fields, transformers \\ nil)

  def map_data_to_headers_list(record_data, header_fields, nil) do
    Enum.map(header_fields, fn k ->
      maybe_from_extra_data(record_data, k)
    end)
  end

  def map_data_to_headers_list(record_data, header_fields, transformers) do
    Enum.map(header_fields, fn k ->
      if Map.has_key?(transformers, k) do
        record_data
        |> maybe_from_extra_data(k)
        |> transformers[k].()
      else
        maybe_from_extra_data(record_data, k)
      end
    end)
  end

  defp maybe_from_extra_data(record, field) do
    if Map.has_key?(record, field) do
      Map.get(record, field)
    else
      get_in(record, [:extra_data, stringify(field)])
    end
  end

  defp stringify(val) when is_atom(val), do: Atom.to_string(val)
  defp stringify(val), do: val

  @doc """
  Creates a directory in the system's temporary directory with a unique name
  """
  @spec create_directory!(String.t()) :: String.t()
  def create_directory!(directory) do
    path = Path.join([System.tmp_dir!(), directory, Uniq.UUID.uuid7(:slug)])

    File.mkdir_p!(path)

    path
  end

  @doc """
  Creates a zip file from the files in the given directory
  """
  @spec create_zip!(String.t()) :: String.t()
  def create_zip!(directory) do
    zip_path = ~c"#{directory}/#{Uniq.UUID.uuid7(:slug)}.zip"
    files = get_files(directory)
    directory_path = ~c"#{directory}/"

    case :zip.create(zip_path, files, [{:cwd, directory_path}]) do
      {:ok, _} ->
        to_string(zip_path)

      {:error, reason} ->
        raise "Error creating zip file: #{inspect(reason)}"
    end
  end

  @doc """
  Returns a list of files in the given directory
  """
  @spec get_files(String.t()) :: list(charlist())
  def get_files(path) do
    path
    |> File.ls!()
    |> Enum.map(&String.to_charlist/1)
  end

  @doc """
  Stores the given data in a CSV file on the local disk. Use store_on_disk/3 to
  have file open and close correctly handled.
  """
  @spec store_local_file(
          any(),
          map() | [map()],
          [String.t()] | [{atom(), String.t()}] | boolean()
        ) :: any()
  def store_local_file(file, data_with_headers, headers) do
    data_with_headers
    |> CSV.encode(separator: ?,, headers: headers)
    |> Enum.each(&IO.write(file, &1))

    file
  end

  @doc """
  Stores the file on the given path on S3 and returns the attachment resource
  """
  @spec store_on_s3!(String.t()) :: Attachment.t()
  def store_on_s3!(path) do
    Attachment.import_from_path!(path)
  end

  @doc """
  Stores the given data in a file on the local disk
  """
  @spec store_on_disk!(
          map() | list(),
          String.t() | File.file_descriptor(),
          [String.t()] | boolean() | nil
        ) ::
          any()
  def store_on_disk!(data, path_or_file, headers \\ false)

  def store_on_disk!(data, path, headers) when is_binary(path) do
    file =
      path
      |> open_file!()
      |> store_local_file(data, headers)

    close_file(file)

    file
  end

  def store_on_disk!(data, file, headers) do
    store_local_file(file, data, headers)
  end

  def open_file!(path) do
    File.open!(path, [:write, :utf8])
  end

  def close_file(file) do
    File.close(file)
  end

  def delete_file!(file_or_path) do
    File.rm!(file_or_path)
  end
end
