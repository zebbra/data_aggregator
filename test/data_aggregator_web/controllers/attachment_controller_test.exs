defmodule DataAggregatorWeb.AttachmentControllerTest do
  @moduledoc false

  use DataAggregatorWeb.ConnCase, async: true

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Files.Attachment.Helpers
  alias DataAggregator.RecordsFixtures

  @example_file "test/support/fixtures/files/gbifch_swiss-species-registry-small.csv"

  setup do
    collection = RecordsFixtures.collection_fixture()

    {:ok, collection: collection}
    {:ok, attachment} = Attachment.import_from_path(@example_file, collection)

    %{attachment: attachment, collection: collection}
  end

  describe "show/2" do
    test "serves attachment with inline disposition", %{conn: conn, attachment: attachment} do
      conn = get(conn, ~p"/attachments/#{attachment.id}")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["text/csv; charset=utf-8"]
      assert get_resp_header(conn, "content-disposition") == ["inline"]
    end

    test "attachment_public_url helper generates correct URL for attachment", %{
      attachment: attachment
    } do
      public_url = Helpers.attachment_public_url(attachment.id)

      # Verify the URL structure is correct regardless of port
      uri = URI.parse(public_url)
      assert uri.scheme == "http"
      assert uri.host == "localhost"
      assert uri.path == "/attachments/#{attachment.id}/download"
    end

    test "returns 404 for non-existent attachment", %{conn: conn} do
      conn = get(conn, ~p"/attachments/fat_nonexistent")

      assert response(conn, 404) == "Unable to find the requested attachment"
    end

    test "returns 404 for invalid attachment id", %{conn: conn} do
      conn = get(conn, ~p"/attachments/invalid_id")

      assert response(conn, 404) == "Unable to find the requested attachment"
    end
  end

  describe "download/2" do
    test "serves attachment with download disposition", %{conn: conn, attachment: attachment} do
      conn = get(conn, ~p"/attachments/#{attachment.id}/download")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["text/csv; charset=utf-8"]

      [disposition] = get_resp_header(conn, "content-disposition")
      assert String.starts_with?(disposition, "attachment; filename=")
      assert String.contains?(disposition, "gbifch_swiss-species-registry-small.csv")
    end

    test "returns 404 for non-existent attachment", %{conn: conn} do
      conn = get(conn, ~p"/attachments/fat_nonexistent/download")

      assert response(conn, 404) == "Unable to find the requested attachment"
    end

    test "returns 404 for invalid attachment id", %{conn: conn} do
      conn = get(conn, ~p"/attachments/invalid_id/download")

      assert response(conn, 404) == "Unable to find the requested attachment"
    end
  end

  describe "content type detection" do
    test "detects correct content type for pdf files", %{collection: collection} do
      # Create a temporary PDF file
      temp_path = Path.join(System.tmp_dir!(), "test.pdf")
      File.write!(temp_path, "%PDF-1.4 test content")

      {:ok, attachment} = Attachment.import_from_path(temp_path, collection)
      conn = get(build_conn(), ~p"/attachments/#{attachment.id}")

      [content_type] = get_resp_header(conn, "content-type")
      assert String.starts_with?(content_type, "application/pdf")

      # Clean up
      File.rm!(temp_path)
      Attachment.destroy(attachment)
    end

    test "detects correct content type for json files", %{collection: collection} do
      # Create a temporary JSON file with actual JSON content
      temp_path = Path.join(System.tmp_dir!(), "test.json")
      File.write!(temp_path, ~s({"test": "content"}))

      {:ok, attachment} = Attachment.import_from_path(temp_path, collection)
      conn = get(build_conn(), ~p"/attachments/#{attachment.id}")

      [content_type] = get_resp_header(conn, "content-type")
      assert String.starts_with?(content_type, "application/json")

      # Clean up
      File.rm!(temp_path)
      Attachment.destroy(attachment)
    end

    test "detects correct content type for unknown extensions", %{collection: collection} do
      # Create a temporary file with unknown extension
      temp_path = Path.join(System.tmp_dir!(), "test.unknown")
      File.write!(temp_path, "some unknown content")

      {:ok, attachment} = Attachment.import_from_path(temp_path, collection)
      conn = get(build_conn(), ~p"/attachments/#{attachment.id}")

      [content_type] = get_resp_header(conn, "content-type")
      assert String.starts_with?(content_type, "application/octet-stream")

      # Clean up
      File.rm!(temp_path)
      Attachment.destroy(attachment)
    end
  end

  describe "filename sanitization" do
    test "sanitizes unsafe characters in filename for download", %{collection: collection} do
      # Create a file with unsafe characters in the name
      unsafe_filename = "test file with spaces & special chars!.txt"
      temp_path = Path.join(System.tmp_dir!(), unsafe_filename)
      File.write!(temp_path, "test content")

      {:ok, attachment} = Attachment.import_from_path(temp_path, collection)
      conn = get(build_conn(), ~p"/attachments/#{attachment.id}/download")

      [disposition] = get_resp_header(conn, "content-disposition")

      # Should contain sanitized filename
      assert String.contains?(disposition, "attachment; filename=")
      # Unsafe characters should be replaced with underscores
      assert String.contains?(disposition, "test_file_with_spaces___special_chars_.txt")

      # Clean up
      File.rm!(temp_path)
      Attachment.destroy(attachment)
    end
  end
end
