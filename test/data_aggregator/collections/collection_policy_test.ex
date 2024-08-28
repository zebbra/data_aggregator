defmodule DataAggregator.Collections.CollectionPolicyTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Collection

  @inst_1 Ash.UUID.generate()
  @inst_2 Ash.UUID.generate()

  describe "as admin" do
    setup do
      actor = %User{
        id: "user_1",
        email: "admin@email.com",
        roles: ["admin"],
        institution_id: @inst_1
      }

      collection_same = %Collection{
        id: "collection_same",
        name: "Collection same",
        grscicoll_institution_key: @inst_1
      }

      collection_other = %Collection{
        id: "collection_other",
        name: "Collection other",
        grscicoll_institution_key: @inst_2
      }

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)
    end

    test "can create collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      collection =
        collection_same
        |> Map.from_struct()
        |> Map.take([:id, :name, :grscicoll_institution_key])

      assert Collection.can_create?(actor, collection)
    end

    test "can create collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:id, :name, :grscicoll_institution_key])

      assert Collection.can_create?(actor, collection)
    end

    test "can update collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_update?(actor, collection_same)
    end

    test "can update collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      assert Collection.can_update?(actor, collection_other)
    end

    test "can destroy collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_destroy?(actor, collection_same)
    end

    test "can destroy collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      assert Collection.can_destroy?(actor, collection_other)
    end
  end

  describe "as collection_digitizer" do
    setup do
      actor = %User{
        id: "user_1",
        email: "collection_digitizer@email.com",
        roles: ["collection_digitizer"],
        institution_id: @inst_1
      }

      collection_same = %Collection{
        id: "collection_same",
        name: "Collection same",
        grscicoll_institution_key: @inst_1
      }

      collection_other = %Collection{
        id: "collection_other",
        name: "Collection other",
        grscicoll_institution_key: @inst_2
      }

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)
    end

    # TODO: How to test? We need an existing grscicoll_institution_key for the changeset to contain it
    # test "can create collection with same institution", %{
    #   actor: actor,
    #   collection_same: collection_same
    # } do
    #   collection =
    #     collection_same
    #     |> Map.from_struct()
    #     |> Map.take([:id, :name, :grscicoll_institution_key])

    #   assert Collection.can_create?(actor, collection)
    # end

    test "cannot create collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:id, :name, :grscicoll_institution_key])

      refute Collection.can_create?(actor, collection)
    end

    test "can update collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_update?(actor, collection_same)
    end

    test "cannot update collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_update?(actor, collection_other)
    end

    test "can destroy collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_destroy?(actor, collection_same)
    end

    test "cannot destroy collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_destroy?(actor, collection_other)
    end
  end

  describe "as data_administrator" do
    setup do
      actor = %User{
        id: "user_1",
        email: "data_administrator@email.com",
        roles: ["data_administrator"],
        institution_id: @inst_1
      }

      collection_same = %Collection{
        id: "collection_same",
        name: "Collection same",
        grscicoll_institution_key: @inst_1
      }

      collection_other = %Collection{
        id: "collection_other",
        name: "Collection other",
        grscicoll_institution_key: @inst_2
      }

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)
    end

    test "cannot create same collection", %{actor: actor, collection_same: collection_same} do
      collection =
        collection_same
        |> Map.from_struct()
        |> Map.take([:id, :name, :grscicoll_institution_key])

      refute Collection.can_create?(actor, collection)
    end

    test "cannot create other collection", %{actor: actor, collection_other: collection_other} do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:id, :name, :grscicoll_institution_key])

      refute Collection.can_create?(actor, collection)
    end

    test "cannot update same collection", %{actor: actor, collection_same: collection_same} do
      refute Collection.can_update?(actor, collection_same)
    end

    test "cannot update other collection", %{actor: actor, collection_other: collection_other} do
      refute Collection.can_update?(actor, collection_other)
    end

    test "cannot destroy same collection", %{actor: actor, collection_same: collection_same} do
      refute Collection.can_destroy?(actor, collection_same)
    end

    test "cannot destroy other collection", %{actor: actor, collection_other: collection_other} do
      refute Collection.can_destroy?(actor, collection_other)
    end
  end
end
