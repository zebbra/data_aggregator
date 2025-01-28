defmodule DataAggregator.Accounts.UserPolicyTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif.RestAPIStub

  @inst_1 RestAPIStub.institution_key()
  @inst_2 RestAPIStub.other_institution_key()

  describe "as admin" do
    setup do
      actor = %User{
        id: "user_1",
        email: "admin@email.com",
        roles: ["admin"],
        institution_id: @inst_1
      }

      same = %User{
        id: "user_2",
        email: "same@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      other = %User{
        id: "user_3",
        email: "other@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_2
      }

      [actor: actor, same: same, other: other]
    end

    test "can read all", %{actor: actor} do
      assert User.can_read?(actor)
    end

    test "can register_with_password same", %{actor: actor, same: same} do
      same = same |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      assert User.can_register_with_password?(actor, same)
    end

    test "can register_with_password other", %{actor: actor, other: other} do
      other = other |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      assert User.can_register_with_password?(actor, other)
    end

    test "can update same institution", %{actor: actor, same: same} do
      assert User.can_update?(actor, same)
    end

    test "can update other institution", %{actor: actor, other: other} do
      assert User.can_update?(actor, other)
    end

    test "can destroy other institution", %{actor: actor, other: other} do
      assert User.can_destroy?(actor, other)
    end

    test "can destroy same institution", %{actor: actor, same: same} do
      assert User.can_destroy?(actor, same)
    end

    test "can update self", %{actor: actor} do
      assert User.can_update?(actor, actor)
    end

    test "cannot destroy self", %{actor: actor} do
      refute User.can_destroy?(actor, actor)
    end
  end

  describe "as collection_administrator" do
    setup do
      actor = %User{
        id: "user_1",
        email: "collection_administrator@email.com",
        roles: ["collection_administrator"],
        institution_id: @inst_1
      }

      same = %User{
        id: "user_2",
        email: "same@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      other = %User{
        id: "user_3",
        email: "data_digitizer@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_2
      }

      [actor: actor, same: same, other: other]
    end

    test "can read all", %{actor: actor} do
      assert User.can_read?(actor)
    end

    test "can register_with_password same institution", %{actor: actor, same: same} do
      same = same |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      assert User.can_register_with_password?(actor, same)
    end

    test "can update same institution", %{actor: actor, same: same} do
      assert User.can_update?(actor, same)
    end

    test "cannot destroy same institution", %{actor: actor, same: same} do
      refute User.can_destroy?(actor, same)
    end

    test "cannot register_with_password other institution", %{actor: actor, other: other} do
      other = other |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      refute User.can_register_with_password?(actor, other)
    end

    test "cannot update other institution", %{actor: actor, other: other} do
      refute User.can_update?(actor, other)
    end

    test "cannot destroy other institution", %{actor: actor, other: other} do
      refute User.can_destroy?(actor, other)
    end

    test "can update self", %{actor: actor} do
      assert User.can_update?(actor, actor)
    end

    test "cannot destroy self", %{actor: actor} do
      refute User.can_destroy?(actor, actor)
    end
  end

  describe "as data_digitizer" do
    setup do
      actor = %User{
        id: "user_1",
        email: "data_digitizer@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      same = %User{
        id: "user_2",
        email: "same@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      other = %User{
        id: "user_3",
        email: "data_digitizer@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_2
      }

      [actor: actor, same: same, other: other]
    end

    test "cannot read all", %{actor: actor} do
      refute User.can_read?(actor)
    end

    test "cannot register_with_password same institution", %{actor: actor, same: same} do
      same = same |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      refute User.can_register_with_password?(actor, same)
    end

    test "cannot update same institution", %{actor: actor, same: same} do
      refute User.can_update?(actor, same)
    end

    test "cannot destroy same institution", %{actor: actor, same: same} do
      refute User.can_destroy?(actor, same)
    end

    test "cannot register_with_password other institution", %{actor: actor, other: other} do
      other = other |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      refute User.can_register_with_password?(actor, other)
    end

    test "cannot update other institution", %{actor: actor, other: other} do
      refute User.can_update?(actor, other)
    end

    test "cannot destroy other institution", %{actor: actor, other: other} do
      refute User.can_destroy?(actor, other)
    end

    test "cannot update self", %{actor: actor} do
      refute User.can_update?(actor, actor)
    end

    test "cannot destroy self", %{actor: actor} do
      refute User.can_destroy?(actor, actor)
    end
  end

  describe "as admin and collection_digitizier and data_digitizer" do
    setup do
      actor = %User{
        id: "user_1",
        email: "admin@email.com",
        roles: ["admin", "collection_administrator", "data_digitizer"],
        institution_id: @inst_1
      }

      same = %User{
        id: "user_2",
        email: "same@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      other = %User{
        id: "user_3",
        email: "other@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_2
      }

      [actor: actor, same: same, other: other]
    end

    test "can read all", %{actor: actor} do
      assert User.can_read?(actor)
    end

    test "can register_with_password same", %{actor: actor, same: same} do
      same = same |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      assert User.can_register_with_password?(actor, same)
    end

    test "can register_with_password other", %{actor: actor, other: other} do
      other = other |> Map.from_struct() |> Map.take([:id, :email, :roles, :institution_id])
      assert User.can_register_with_password?(actor, other)
    end

    test "can update same institution", %{actor: actor, same: same} do
      assert User.can_update?(actor, same)
    end

    test "can update other institution", %{actor: actor, other: other} do
      assert User.can_update?(actor, other)
    end

    test "can destroy other institution", %{actor: actor, other: other} do
      assert User.can_destroy?(actor, other)
    end

    test "can destroy same institution", %{actor: actor, same: same} do
      assert User.can_destroy?(actor, same)
    end

    test "can update self", %{actor: actor} do
      assert User.can_update?(actor, actor)
    end

    test "cannot destroy self", %{actor: actor} do
      refute User.can_destroy?(actor, actor)
    end
  end
end
