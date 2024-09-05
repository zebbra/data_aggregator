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
    Map.new(header_fields, fn {k, v} -> {v, Map.get(record_data, k)} end)
  end

  def map_data_to_headers(record_data, header_fields, transformers) do
    Map.new(header_fields, fn {k, v} ->
      if Map.has_key?(transformers, k) do
        {v, transformers[k].(Map.get(record_data, k))}
      else
        {v, Map.get(record_data, k)}
      end
    end)
  end

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
  Stores the given data in a CSV file on the local disk
  """
  @spec store_local_file(any(), map() | [map()], [String.t()] | [{atom(), String.t()}]) :: any()
  def store_local_file(file, data_with_headers, headers) do
    data_with_headers
    |> CSV.encode(separator: ?,, headers: headers)
    |> Stream.each(&IO.write(file, &1))
    |> Stream.run()

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
  @spec store_on_disk!(map(), String.t(), [String.t()]) :: any()
  def store_on_disk!(data, path, headers) do
    file =
      path
      |> File.open!([:write, :utf8])
      |> store_local_file(data, headers)

    File.close(file)

    file
  end
end
