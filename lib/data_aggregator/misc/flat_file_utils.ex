defmodule DataAggregator.Misc.FlatFileUtils do
  @moduledoc """
  Utility functions for working with CSV files
  """
  alias DataAggregator.Files.Attachment

  @doc """
   gives you a map of all relevant dwc header fields and the record values
   in the structure of `%{"verbatimLocality" => nil, "kingdom" => "My Kingdom", ..}`
  """
  @spec map_data_to_headers(map(), list()) :: map()
  def map_data_to_headers(record_data, header_fields) do
    Map.new(header_fields, fn {k, v} -> {v, Map.get(record_data, k)} end)
  end

  @doc """
  Creates a directory in the system's temporary directory with a unique name
  """
  @spec create_directory!(String.t()) :: String.t()
  def create_directory!(directory) do
    path = Path.join([System.tmp_dir!(), directory, Ecto.UUID.generate()])

    File.mkdir_p!(path)

    path
  end

  @doc """
  Creates a zip file from the files in the given directory
  """
  @spec create_zip!(String.t()) :: String.t()
  def create_zip!(directory) do
    zip_path = ~c"#{directory}/#{Ecto.UUID.generate()}.zip"
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
  @spec store_local_file(any(), map()) :: any()
  def store_local_file(file, data_with_headers) do
    data_with_headers
    |> CSV.encode(separator: ?,, headers: true)
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
  @spec store_on_disk!(map(), String.t()) :: any()
  def store_on_disk!(data, path) do
    file =
      path
      |> File.open!([:write, :utf8])
      |> store_local_file(data)

    File.close(file)

    file
  end
end
