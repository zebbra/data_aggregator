defmodule DataAggregator.Files.DummyTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Test.User

  @example_file "test/support/fixtures/files/gbifch_swiss-species-registry-small.csv"

  test "create a dummy with an attachment" do
    params = %{
      name: "test",
      avatar_path: @example_file
    }

    user =
      User
      |> Ash.Changeset.for_create(:with_avatar, params)
      |> Ash.create!()

    assert user.avatar.filename == "gbifch_swiss-species-registry-small.csv"

    assert user.avatar.url ==
             "http://localhost:4002/files/#{user.avatar.id}/gbifch_swiss-species-registry-small.csv"
  end
end
