defmodule DataAggregator.Collections.CollectionPolicyTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  @inst_1 RestAPIStub.institution_key()
  @inst_2 RestAPIStub.other_institution_key()

  describe "as admin" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      actor = %User{
        id: "user_1",
        email: "admin@email.com",
        roles: ["admin"],
        institution_id: @inst_1
      }

      collection_same =
        collection_fixture(%{
          name: "Collection same",
          grscicoll_institution_key: @inst_1,
          grscicoll_reference: RestAPIStub.grscicoll_reference()
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)

      collections = Collection.read!(actor: actor)
      assert length(collections) == 2
    end

    test "can create collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      collection =
        collection_same
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

      assert Collection.can_create?(actor, collection)
    end

    test "can create collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

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

    test "can enqueue encoding for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_enqueue_encoding?(actor, collection_same, %{})
    end

    test "can enqueue encoding for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      assert Collection.can_enqueue_encoding?(actor, collection_other, %{})
    end

    test "can validate for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      assert Collection.can_start_validations?(actor, collection_other, %{})
    end

    test "can validate for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_start_validations?(actor, collection_same, %{})
    end

    test "can set_publishing for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_set_publishing?(actor, collection_same)
    end

    test "can set_publishing for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      assert Collection.can_set_publishing?(actor, collection_other)
    end

    test "can publish", %{
      actor: actor
    } do
      assert Collection.can_publish?(actor, %Publication{})
    end

    set_test_cases = [
      {:can_set_mapping?, "set mapping"},
      {:can_set_importing?, "set importing"},
      {:can_set_exporting?, "set exporting"},
      {:can_set_encoding?, "set encoding"},
      {:can_set_validating?, "set validating"},
      {:can_set_deleting?, "set deleting"},
      {:can_set_idle?, "set idle"},
      {:can_set_idle_encoding?, "set idle encoding"},
      {:can_cancel_action?, "cancel action"}
    ]

    for {method, method_description} <- set_test_cases do
      test "can #{method_description} for collection with same institution", %{
        actor: actor,
        collection_same: collection_same
      } do
        assert apply(Collection, unquote(method), [actor, collection_same, %{}])
      end

      test "can #{method_description} for collection with other institution", %{
        actor: actor,
        collection_other: collection_other
      } do
        assert apply(Collection, unquote(method), [actor, collection_other, %{}])
      end
    end
  end

  describe "as collection_administrator" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      actor = %User{
        id: "user_1",
        email: "collection_administrator@email.com",
        roles: ["collection_administrator"],
        institution_id: @inst_1
      }

      collection_same =
        collection_fixture(%{
          name: "Collection same",
          grscicoll_institution_key: @inst_1,
          grscicoll_reference: RestAPIStub.grscicoll_reference()
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)

      collections = Collection.read!(actor: actor)
      assert length(collections) == 1
    end

    test "can create collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      collection =
        collection_same
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

      assert Collection.can_create?(actor, collection)
    end

    test "cannot create collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

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

    test "cannot enqueue encoding for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      refute Collection.can_enqueue_encoding?(actor, collection_same, %{})
    end

    test "cannot enqueue encoding for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_enqueue_encoding?(actor, collection_other, %{})
    end

    test "can set_publishing for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_set_publishing?(actor, collection_same)
    end

    test "cannot set_publishing for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_set_publishing?(actor, collection_other)
    end

    test "can publish", %{
      actor: actor
    } do
      assert Collection.can_publish?(actor, %Publication{})
    end

    set_test_cases = [
      {:can_set_mapping?, "set mapping"},
      {:can_set_importing?, "set importing"},
      {:can_set_exporting?, "set exporting"},
      {:can_set_encoding?, "set encoding"},
      {:can_set_validating?, "set validating"},
      {:can_set_deleting?, "set deleting"},
      {:can_set_idle?, "set idle"},
      {:can_set_idle_encoding?, "set idle encoding"},
      {:can_cancel_action?, "cancel action"}
    ]

    for {method, method_description} <- set_test_cases do
      test "cannot #{method_description} for collection with same institution", %{
        actor: actor,
        collection_same: collection_same
      } do
        refute apply(Collection, unquote(method), [actor, collection_same])
      end

      test "cannot #{method_description} for collection with other institution", %{
        actor: actor,
        collection_other: collection_other
      } do
        refute apply(Collection, unquote(method), [actor, collection_other])
      end
    end
  end

  describe "as data_digitizer" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      actor = %User{
        id: "user_1",
        email: "data_digitizer@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      collection_same =
        collection_fixture(%{
          name: "Collection same",
          grscicoll_institution_key: @inst_1,
          grscicoll_reference: RestAPIStub.grscicoll_reference()
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)

      collections = Collection.read!(actor: actor)
      assert length(collections) == 1
    end

    test "cannot create same collection", %{actor: actor, collection_same: collection_same} do
      collection =
        collection_same
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

      refute Collection.can_create?(actor, collection)
    end

    test "cannot create other collection", %{actor: actor, collection_other: collection_other} do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

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

    test "cannot cancel action for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      refute Collection.can_cancel_action?(actor, collection_same)
    end

    test "cannot cancel action for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_cancel_action?(actor, collection_other)
    end

    test "can enqueue encoding for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_enqueue_encoding?(actor, collection_same, %{})
    end

    test "cannot enqueue encoding for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_enqueue_encoding?(actor, collection_other, %{})
    end

    test "cannot set_publishing for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      refute Collection.can_set_publishing?(actor, collection_same)
    end

    test "cannot set_publishing for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_set_publishing?(actor, collection_other)
    end

    test "cannot publish", %{
      actor: actor
    } do
      refute Collection.can_publish?(actor, %Publication{})
    end

    set_test_cases = [
      {:can_set_mapping?, "set mapping"},
      {:can_set_importing?, "set importing"},
      {:can_set_exporting?, "set exporting"},
      {:can_set_encoding?, "set encoding"},
      {:can_set_validating?, "set validating"},
      {:can_set_deleting?, "set deleting"},
      {:can_set_idle?, "set idle"},
      {:can_set_idle_encoding?, "set idle encoding"}
    ]

    for {method, method_description} <- set_test_cases do
      test "can #{method_description} for collection with same institution", %{
        actor: actor,
        collection_same: collection_same
      } do
        assert apply(Collection, unquote(method), [actor, collection_same])
      end

      test "cannot #{method_description} for collection with other institution", %{
        actor: actor,
        collection_other: collection_other
      } do
        refute apply(Collection, unquote(method), [actor, collection_other])
      end
    end
  end

  describe "as collection_administrator and data_digitizer" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      actor = %User{
        id: "user_1",
        email: "data_digitizer@email.com",
        roles: ["collection_administrator", "data_digitizer"],
        institution_id: @inst_1
      }

      collection_same =
        collection_fixture(%{
          name: "Collection same",
          grscicoll_institution_key: @inst_1,
          grscicoll_reference: RestAPIStub.grscicoll_reference()
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      [actor: actor, collection_same: collection_same, collection_other: collection_other]
    end

    test "can read all", %{actor: actor} do
      assert Collection.can_read?(actor)

      collections = Collection.read!(actor: actor)
      assert length(collections) == 1
    end

    test "can create same collection", %{actor: actor, collection_same: collection_same} do
      collection =
        collection_same
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

      assert Collection.can_create?(actor, collection)
    end

    test "cannot create other collection", %{actor: actor, collection_other: collection_other} do
      collection =
        collection_other
        |> Map.from_struct()
        |> Map.take([:name, :type, :grscicoll_reference, :grscicoll_institution_key])

      refute Collection.can_create?(actor, collection)
    end

    test "can update same collection", %{actor: actor, collection_same: collection_same} do
      assert Collection.can_update?(actor, collection_same)
    end

    test "cannot update other collection", %{actor: actor, collection_other: collection_other} do
      refute Collection.can_update?(actor, collection_other)
    end

    test "can destroy same collection", %{actor: actor, collection_same: collection_same} do
      assert Collection.can_destroy?(actor, collection_same)
    end

    test "cannot destroy other collection", %{actor: actor, collection_other: collection_other} do
      refute Collection.can_destroy?(actor, collection_other)
    end

    test "can enqueue encoding for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_enqueue_encoding?(actor, collection_same, %{})
    end

    test "cannot enqueue encoding for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_enqueue_encoding?(actor, collection_other, %{})
    end

    test "can set_publishing for collection with same institution", %{
      actor: actor,
      collection_same: collection_same
    } do
      assert Collection.can_set_publishing?(actor, collection_same)
    end

    test "cannot set_publishing for collection with other institution", %{
      actor: actor,
      collection_other: collection_other
    } do
      refute Collection.can_set_publishing?(actor, collection_other)
    end

    test "can publish", %{
      actor: actor
    } do
      assert Collection.can_publish?(actor, %Publication{})
    end

    set_test_cases = [
      {:can_set_mapping?, "set mapping"},
      {:can_set_importing?, "set importing"},
      {:can_set_exporting?, "set exporting"},
      {:can_set_encoding?, "set encoding"},
      {:can_set_validating?, "set validating"},
      {:can_set_deleting?, "set deleting"},
      {:can_set_idle?, "set idle"},
      {:can_set_idle_encoding?, "set idle encoding"}
    ]

    for {method, method_description} <- set_test_cases do
      test "can #{method_description} for collection with same institution", %{
        actor: actor,
        collection_same: collection_same
      } do
        assert apply(Collection, unquote(method), [actor, collection_same, %{}])
      end

      test "cannot #{method_description} for collection with other institution", %{
        actor: actor,
        collection_other: collection_other
      } do
        refute apply(Collection, unquote(method), [actor, collection_other, %{}])
      end
    end
  end
end
