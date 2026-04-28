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
      opts =
        @csv_read_opts
        |> Keyword.merge(opts)
        |> Keyword.put(:delimiter, delimiter)

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

    Explorer.DataFrame.from_parquet(file, opts)
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

  @doc """
  Returns the column names of a tabular file (CSV, IPC, or Parquet) without
  materializing its body.

  Uses a lazy Polars frame and reads the names from the cached schema.
  """
  def column_names(file) when is_binary(file) do
    with {:ok, ldf} <- from_file(file, lazy: true) do
      {:ok, Explorer.DataFrame.names(ldf)}
    end
  end

  @doc """
  Returns the column dtypes of a tabular file (CSV, IPC, or Parquet) without
  materializing its body.

  CSV reads use `infer_schema_length: 0`, so all CSV columns come back as
  `:string`. IPC and Parquet dtypes come from the file's schema metadata.
  """
  def column_dtypes(file) when is_binary(file) do
    with {:ok, ldf} <- from_file(file, lazy: true) do
      {:ok, Explorer.DataFrame.dtypes(ldf)}
    end
  end

  @doc """
  Returns the total row count of a tabular file without materializing it.

  Builds a lazy Polars query that aggregates `Series.size/1` over a single
  column and computes it. Polars compiles this to a streaming scan that
  reports total row count (including nil rows) without holding rows in
  memory.
  """
  def row_count(file) when is_binary(file) do
    with {:ok, ldf} <- from_file(file, lazy: true) do
      [first_col | _] = Explorer.DataFrame.names(ldf)

      rows =
        ldf
        |> Explorer.DataFrame.summarise_with(fn lf ->
          [n: Explorer.Series.size(lf[first_col])]
        end)
        |> Explorer.DataFrame.compute()
        |> Explorer.DataFrame.pull("n")
        |> Explorer.Series.first()

      {:ok, rows}
    end
  end

  def maybe_parse_polaris_error(error) when is_exception(error),
    do: error |> Exception.message() |> maybe_parse_polaris_error()

  def maybe_parse_polaris_error(message) when is_binary(message) do
    case Regex.run(
           ~r/Polars Error: could not parse `(.*?)` as dtype `(.*?)` at column '(.*?)'/,
           message
         ) do
      [_, value, dtype, column] ->
        "Could not parse '#{value}' as data type '#{dtype}' for field '#{column}'. Please verify your data."

      nil ->
        message
    end
  end

  def maybe_parse_polaris_error(message), do: message
end
