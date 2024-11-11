defmodule DataAggregator.Records.DataFrame do
  @moduledoc """
  Helper functions to work with import data as `Explorer.DataFrame`.

  At the moment only CSV files are supported.
  """

  require Logger

  @csv_exts ~w(.csv .tsv .txt)
  # disable schema inference
  @csv_read_opts [parse_dates: true, infer_schema_length: 0]
  @csv_write_opts []
  @csv_delimiters [",", ";", "|", "\t"]

  @ipc_exts ~w(.arrow .ipc)
  @ipc_read_opts []
  @ipc_write_opts []

  @pqt_exts ~w(.parquet .pqt)
  @pqt_read_opts []
  @pqt_write_opts []

  @supported_exts @csv_exts ++ @ipc_exts ++ @pqt_exts
  def supported_exts, do: @supported_exts

  @supported_image_file_upload_exts ~w(.zip)
  def supported_image_file_upload_exts, do: @supported_image_file_upload_exts

  @doc """
  Returns a `DataFrame` from the given file.
  """
  def from_file(file, opts \\ []) when is_binary(file) do
    case detect_format(file) do
      :csv -> from_csv(file, opts)
      :ipc -> from_ipc(file, opts)
      :pqt -> from_pqt(file, opts)
      nil -> from_csv(file, opts)
    end
  end

  def from_file!(file, opts \\ []) when is_binary(file) do
    case from_file(file, opts) do
      {:ok, df} -> df
      {:error, error} -> raise error
    end
  end

  def from_csv(file, opts \\ []) do
    with {:ok, delimiter} <- detect_csv_delimiter(file) do
      opts = @csv_read_opts |> Keyword.merge(opts) |> Keyword.put(:delimiter, delimiter)
      Logger.debug("Reading CSV file #{inspect(file)} with options: #{inspect(opts)}")

      Explorer.DataFrame.from_csv(file, opts)
    end
  end

  def from_ipc(file, opts \\ []) do
    opts = Keyword.merge(@ipc_read_opts, opts)
    Logger.debug("Reading Arrow file #{inspect(file)} with options: #{inspect(opts)}")

    Explorer.DataFrame.from_ipc(file, opts)
  end

  def from_pqt(file, opts \\ []) do
    opts = Keyword.merge(@pqt_read_opts, opts)
    Logger.debug("Reading Parquet file #{inspect(file)} with options: #{inspect(opts)}")

    Explorer.DataFrame.from_parquet(file)
  end

  def to_file(df, file, opts \\ []) when is_binary(file) do
    case detect_format_from_ext(file) do
      :csv -> to_csv(df, file, opts)
      :ipc -> to_ipc(df, file, opts)
      :pqt -> to_pqt(df, file, opts)
      nil -> {:error, "Unknown file format for #{inspect(file)}"}
    end
  end

  def to_file!(df, file) when is_binary(file) do
    case to_file(df, file) do
      :ok -> :ok
      {:error, error} -> raise error
    end
  end

  def to_csv(df, file, opts \\ []) do
    opts = Keyword.merge(@csv_write_opts, opts)
    Logger.debug("Writing CSV file #{inspect(file)} with options: #{inspect(opts)}")
    Explorer.DataFrame.to_csv(df, file, opts)
  end

  def to_ipc(df, file, opts \\ []) do
    opts = Keyword.merge(@ipc_write_opts, opts)
    Logger.debug("Writing Arrow file #{inspect(file)} with options: #{inspect(opts)}")
    Explorer.DataFrame.to_ipc(df, file, opts)
  end

  def to_pqt(df, file, opts \\ []) do
    opts = Keyword.merge(@pqt_write_opts, opts)
    Logger.debug("Writing Parquet file #{inspect(file)} with options: #{inspect(opts)}")
    Explorer.DataFrame.to_parquet(df, file, opts)
  end

  def detect_format(filename) do
    with nil <- detect_format_from_ext(filename) do
      detect_format_from_content(filename)
    end
  end

  def detect_format_from_ext(filename) do
    ext = Path.extname(filename)

    cond do
      ext in @csv_exts -> :csv
      ext in @ipc_exts -> :ipc
      ext in @pqt_exts -> :pqt
      true -> nil
    end
  end

  def detect_format_from_content(filename) do
    [header] =
      filename
      |> File.stream!(6)
      |> Enum.take(1)

    case header do
      "ARROW1" <> _ -> :ipc
      "PAR1" <> _ -> :pqt
      _ -> nil
    end
  end

  def detect_csv_delimiter(file) do
    chars =
      file
      |> File.stream!()
      |> Stream.take(1)
      |> Enum.at(0)
      |> String.graphemes()
      |> Enum.frequencies()

    delimiter = Enum.max_by(@csv_delimiters, &Map.get(chars, &1, 0))

    case Map.get(chars, delimiter) do
      nil -> {:error, "Could not detect CSV delimiter (checked #{@csv_delimiters})"}
      _ -> {:ok, delimiter}
    end
  rescue
    error -> {:error, error}
  end

  def maybe_parse_polaris_error("Polars Error: could not parse `" <> message) do
    [parts] = Regex.scan(~r/(.*)` as dtype `(.*)` at column '(.*)' \(column number/, message)

    if length(parts) == 4 do
      [_, value, dtype, column] = parts

      "Could not parse '#{value}' as data type '#{dtype}' for field '#{column}'. Please verify your data."
    else
      "Polars Error: could not parse `" <> message
    end
  end

  def maybe_parse_polaris_error(message), do: message
end
