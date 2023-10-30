defmodule DataAggregator.Files.DummyTest do
  use DataAggregator.DataCase

  alias DataAggregator.Files.Attachment

  defmodule User do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshUUID]

    ets do
      table :files_dummy
      private? true
    end

    actions do
      create :with_avatar do
        argument :avatar_path, :string, allow_nil?: false
        change manage_relationship(:avatar_path, :avatar, value_is_key: :path, type: :create)
      end
    end

    attributes do
      uuid_attribute :id, prefix: "fat"
      attribute :name, :string, allow_nil?: false
    end

    relationships do
      belongs_to :avatar, Attachment do
        api DataAggregator.Files
      end
    end
  end

  defmodule Registry do
    use Ash.Registry

    entries do
      entry User
    end
  end

  defmodule Api do
    use Ash.Api

    resources do
      registry Registry
    end
  end

  test "create a dummy with an attachment" do
    params = %{
      name: "test",
      avatar_path: "seed/gchdata-thesaurus.xlsx.zip"
    }

    user =
      User
      |> Ash.Changeset.for_create(:with_avatar, params)
      |> Api.create!()

    assert user.avatar.filename == "gchdata-thesaurus.xlsx.zip"

    assert user.avatar.url ==
             "http://localhost:4002/files/#{user.avatar.id}/gchdata-thesaurus.xlsx.zip"
  end
end
