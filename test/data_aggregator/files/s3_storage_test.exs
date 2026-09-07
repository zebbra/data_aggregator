defmodule DataAggregator.Files.S3StorageTest do
  @moduledoc """
  Guards that S3 uploads do not carry a canned ACL.

  `Waffle.Storage.S3` always sends `x-amz-acl` (defaulting to `private`), which SWITCH
  Ceph rejects with `403 AccessDenied`. See
  https://github.com/zebbra/data_aggregator/issues/1099
  """

  use ExUnit.Case, async: false

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.S3Storage
  alias DataAggregator.Files.Store

  @example_file "test/support/fixtures/files/museum-dataset-import-example-xs.csv"

  defmodule RecordingClient do
    @moduledoc false
    @behaviour ExAws.Request.HttpClient

    @impl true
    def request(method, url, _body, headers, _http_opts) do
      send(:s3_storage_probe, {:req, method, url, headers})

      cond do
        String.contains?(url, "uploads=1") ->
          xml =
            "<InitiateMultipartUploadResult><Bucket>b</Bucket><Key>k</Key>" <>
              "<UploadId>UPLOAD_ID</UploadId></InitiateMultipartUploadResult>"

          {:ok, %{status_code: 200, headers: [], body: xml}}

        String.contains?(url, "partNumber") ->
          {:ok, %{status_code: 200, headers: [{"ETag", "\"etag1\""}], body: ""}}

        true ->
          xml =
            "<CompleteMultipartUploadResult><Location>l</Location><Bucket>b</Bucket>" <>
              "<Key>k</Key><ETag>\"etag1\"</ETag></CompleteMultipartUploadResult>"

          {:ok, %{status_code: 200, headers: [], body: xml}}
      end
    end
  end

  setup do
    Process.register(self(), :s3_storage_probe)

    previous_waffle = Application.get_all_env(:waffle)
    previous_ex_aws = Application.get_all_env(:ex_aws)

    Application.put_env(:waffle, :bucket, "test-bucket")

    Application.put_env(:ex_aws, :access_key_id, "AKIAEXAMPLE")
    Application.put_env(:ex_aws, :secret_access_key, "secret")
    Application.put_env(:ex_aws, :region, "us-east-1")
    Application.put_env(:ex_aws, :http_client, RecordingClient)
    Application.put_env(:ex_aws, :s3, scheme: "https://", host: "example.invalid", port: 443)

    on_exit(fn ->
      restore_env(:waffle, previous_waffle)
      restore_env(:ex_aws, previous_ex_aws)
    end)

    :ok
  end

  test "uploads do not send a canned ACL" do
    assert {:ok, "probe.csv"} = upload_with(S3Storage)

    assert acl_headers() == []
  end

  test "the initiate request is still signed, without x-amz-acl in the signed headers" do
    assert {:ok, "probe.csv"} = upload_with(S3Storage)

    assert [{:post, url, headers} | _] = requests()
    assert url =~ "uploads=1"

    authorization = header(headers, "authorization")

    assert authorization =~ "AWS4-HMAC-SHA256"
    assert authorization =~ "SignedHeaders=content-length;host;x-amz-content-sha256;x-amz-date"
    refute authorization =~ "x-amz-acl"
  end

  test "stock Waffle.Storage.S3 would send x-amz-acl (documents why S3Storage exists)" do
    assert {:ok, "probe.csv"} = upload_with(Waffle.Storage.S3)

    assert acl_headers() == ["private"]
  end

  defp upload_with(storage) do
    Application.put_env(:waffle, :storage, storage)

    attachment = %Attachment{id: "fat_probe", filename: "probe.csv", byte_size: 1}

    Store.store({%{path: @example_file, filename: "probe.csv"}, attachment})
  end

  defp requests(acc \\ []) do
    receive do
      {:req, method, url, headers} -> requests([{method, url, headers} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp acl_headers do
    for {_method, _url, headers} <- requests(),
        value = header(headers, "x-amz-acl"),
        do: value
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {key, value} ->
      if String.downcase(to_string(key)) == name, do: value
    end)
  end

  defp restore_env(app, previous) do
    for {key, _value} <- Application.get_all_env(app), do: Application.delete_env(app, key)
    for {key, value} <- previous, do: Application.put_env(app, key, value)
  end
end
