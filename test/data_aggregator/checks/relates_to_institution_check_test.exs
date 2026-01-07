defmodule DataAggregator.Checks.RelatesToInstitutionCheckTest do
  use DataAggregator.DataCase, async: true
  use Mimic

  alias Ash.Policy.Authorizer
  alias Ash.Resource.Actions
  alias DataAggregator.Accounts.User
  alias DataAggregator.Checks.RelatesToInstitutionCheck
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection

  describe "describe/1" do
    test "returns correct description" do
      assert RelatesToInstitutionCheck.describe(foreign_key: :institution_id, path: []) ==
               "actor is related to the institution by foreign key institution_id"

      assert RelatesToInstitutionCheck.describe(
               foreign_key: :grscicoll_institution_key,
               path: [:collection]
             ) ==
               "actor is related to the institution by foreign key collection.grscicoll_institution_key"
    end
  end

  describe "requires_original_data?/2" do
    test "returns false" do
      refute RelatesToInstitutionCheck.requires_original_data?(nil, nil)
    end
  end

  describe "match?/3" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      institution_id = "5b487a79-76ef-4615-93d9-f4ea25a40c33"
      user = %User{institution_id: institution_id}

      changeset =
        Ash.Changeset.for_create(Collection, :create, %{
          grscicoll_institution_key: institution_id,
          name: "Test Collection",
          grscicoll_reference: "TEST-REF",
          type: :botany
        })

      [changeset: changeset, user: user, institution_id: institution_id]
    end

    test "returns false when actor is nil" do
      refute RelatesToInstitutionCheck.match?(nil, %Authorizer{},
               foreign_key: :grscicoll_institution_key,
               path: []
             )
    end

    test "matches when actor institution_id equals resource key (direct attribute)", %{
      changeset: changeset,
      user: actor
    } do
      authorizer = %Authorizer{changeset: changeset}

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: []
             )
    end

    test "does not match when ids differ", %{
      changeset: changeset
    } do
      actor = %User{institution_id: Ash.UUID.generate()}

      authorizer = %Authorizer{changeset: changeset}

      refute RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: []
             )
    end

    test "matches when resource foreign key is nil", %{
      changeset: changeset,
      user: actor
    } do
      changeset = Ash.Changeset.force_change_attribute(changeset, :grscicoll_institution_key, nil)

      authorizer = %Authorizer{changeset: changeset}

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: []
             )
    end

    test "matches using Collection as tenant when changeset is nil", %{
      user: actor,
      institution_id: institution_id
    } do
      tenant = %Collection{grscicoll_institution_key: institution_id}

      authorizer = %Authorizer{
        changeset: nil,
        action_input: %Ash.ActionInput{tenant: tenant}
      }

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: []
             )
    end

    test "matches traversing path for Update action", %{
      user: actor,
      institution_id: institution_id
    } do
      # Mocking data on changeset for Update
      data_with_relation = %{
        collection: %{
          grscicoll_institution_key: institution_id
        }
      }

      changeset = %Ash.Changeset{
        data: data_with_relation,
        action_type: :update
      }

      action = %Actions.Update{}
      authorizer = %Authorizer{changeset: changeset, action: action}

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: [:collection]
             )
    end

    test "matches traversing path for Destroy action", %{
      user: actor,
      institution_id: institution_id
    } do
      data_with_relation = %{
        collection: %{
          grscicoll_institution_key: institution_id
        }
      }

      changeset = %Ash.Changeset{
        data: data_with_relation,
        action_type: :destroy
      }

      action = %Actions.Destroy{}
      authorizer = %Authorizer{changeset: changeset, action: action}

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: [:collection]
             )
    end

    test "matches traversing path for Create action (using arguments)", %{
      user: actor,
      institution_id: institution_id
    } do
      arguments = %{
        collection: %{
          grscicoll_institution_key: institution_id
        }
      }

      changeset = %Ash.Changeset{
        arguments: arguments,
        action_type: :create
      }

      action = %Actions.Create{}
      authorizer = %Authorizer{changeset: changeset, action: action}

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: [:collection]
             )
    end

    test "matches when path traversal fails (nil encountered)", %{
      user: actor
    } do
      data_with_nil_relation = %{
        collection: nil
      }

      changeset = %Ash.Changeset{
        data: data_with_nil_relation,
        action_type: :update
      }

      action = %Actions.Update{}
      authorizer = %Authorizer{changeset: changeset, action: action}

      assert RelatesToInstitutionCheck.match?(actor, authorizer,
               foreign_key: :grscicoll_institution_key,
               path: [:collection]
             )
    end
  end
end
