defmodule DataAggregator.PublicationPolicyTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  @inst_1 RestAPIStub.institution_key()

  describe "checking policies for publishing" do
    setup do
      collection_administrator = %User{
        id: "user_1",
        email: "collection_administrator@email.com",
        roles: ["collection_administrator"],
        institution_id: @inst_1
      }

      data_digitizer = %User{
        id: "user_2",
        email: "data_digitizer@email.com",
        roles: ["data_digitizer"],
        institution_id: @inst_1
      }

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      publication =
        Publication.create!(
          %{
            name: "Publication 2",
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      [
        collection_administrator: collection_administrator,
        data_digitizer: data_digitizer,
        publication: publication
      ]
    end

    test "collection_administrator can read", %{
      collection_administrator: collection_administrator
    } do
      assert Publication.can_read?(collection_administrator)
    end

    test "data_digitizer can read", %{
      data_digitizer: data_digitizer
    } do
      assert Publication.can_read?(data_digitizer)
    end

    test "collection_administrator can update", %{
      collection_administrator: collection_administrator,
      publication: publication
    } do
      assert Publication.can_update?(collection_administrator, publication)
    end

    test "data_digitizer can update", %{
      data_digitizer: data_digitizer,
      publication: publication
    } do
      assert Publication.can_update?(data_digitizer, publication)
    end

    test "data_digitizer can't destroy", %{
      data_digitizer: data_digitizer,
      publication: publication
    } do
      refute Publication.can_destroy?(data_digitizer, publication)
    end

    test "collection_administrator can destroy", %{
      collection_administrator: collection_administrator,
      publication: publication
    } do
      assert Publication.can_destroy?(collection_administrator, publication)
    end

    test "collection_administrator can publish", %{
      collection_administrator: collection_administrator,
      publication: publication
    } do
      assert Collection.can_publish?(collection_administrator, publication)
    end

    test "data_digitizer can't publish", %{
      data_digitizer: data_digitizer,
      publication: publication
    } do
      refute Collection.can_publish?(data_digitizer, publication)
    end
  end
end
