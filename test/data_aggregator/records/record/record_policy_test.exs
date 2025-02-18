defmodule DataAggregator.Records.RecordPolicyTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Accounts.User
  alias DataAggregator.Gbif
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  @inst_1 RestAPIStub.institution_key()
  @inst_2 RestAPIStub.other_institution_key()

  describe "as admin" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      actor = %User{
        id: "usr_02z55LjrUZFNkbZy1tVKje",
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

      import_same = Import.create!(collection_same, tenant: collection_same)

      record_same =
        record_fixture(%{
          collection: collection_same
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      import_other = Import.create!(collection_other, tenant: collection_other)

      record_other =
        record_fixture(%{
          collection: collection_other
        })

      [
        actor: actor,
        import_same: import_same,
        record_same: record_same,
        import_other: import_other,
        record_other: record_other,
        collection_same: collection_same,
        collection_other: collection_other
      ]
    end

    test "can read all", %{
      actor: actor,
      collection_same: collection_same,
      collection_other: collection_other
    } do
      assert Record.can_read?(actor)

      records = Record.read!(actor: actor, tenant: collection_same)
      assert length(records) == 1

      records = Record.read!(actor: actor, tenant: collection_other)
      assert length(records) == 1
    end

    test "can create record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      record = Map.from_struct(record_same)

      assert Record.can_create?(actor, record)
    end

    test "can create record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      record = Map.from_struct(record_other)

      assert Record.can_create?(actor, record)
    end

    test "can bulk_import same import", %{actor: actor, import_same: import} do
      assert Record.can_bulk_import?(actor, import, %{})
    end

    test "can bulk_import other import", %{actor: actor, import_other: import} do
      assert Record.can_bulk_import?(actor, import, %{})
    end

    test "can update record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      assert Record.can_update?(actor, record_same)
    end

    test "can update record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      assert Record.can_update?(actor, record_other)
    end

    test "can destroy record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      assert Record.can_destroy?(actor, record_same)
    end

    test "can destroy record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      assert Record.can_destroy?(actor, record_other)
    end

    set_test_cases = [
      {:can_update?, "update"},
      {:can_set_imported?, "set_imported"},
      {:can_set_encoding?, "set_encoding"},
      {:can_set_encoded?, "set_encoded"},
      {:can_set_encoding_failed?, "set_encoding_failed"},
      {:can_enqueue_encoder?, "enqueue_encoder"},
      {:can_check_if_fast_track_pubished?, "check_if_fast_track_pubished"},
      {:can_enqueue_fast_track_checker?, "enqueue_fast_track_checker"},
      {:can_update_last_validation_started_at?, "update_last_validation_started_at"}
    ]

    for {method, method_description} <- set_test_cases do
      test "can #{method_description} for record with same institution", %{
        actor: actor,
        record_same: record_same
      } do
        assert apply(Record, unquote(method), [actor, record_same])
      end

      test "can #{method_description} for record with other institution", %{
        actor: actor,
        record_other: record_other
      } do
        assert apply(Record, unquote(method), [actor, record_other])
      end
    end
  end

  describe "as collection_administrator" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      actor = %User{
        id: "usr_02z55LjrUZFNkbZy1tVKje",
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

      import_same = Import.create!(collection_same, tenant: collection_same)

      record_same =
        record_fixture(%{
          collection: collection_same
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      record_other =
        record_fixture(%{
          collection: collection_other
        })

      [
        actor: actor,
        import_same: import_same,
        record_same: record_same,
        record_other: record_other,
        collection_same: collection_same,
        collection_other: collection_other
      ]
    end

    test "can read all", %{actor: actor, collection_same: tenant} do
      assert Record.can_read?(actor)

      records = Record.read!(actor: actor, tenant: tenant)
      assert length(records) == 1
    end

    test "cannot read from other collection", %{actor: actor, collection_other: tenant} do
      records = Record.read!(actor: actor, tenant: tenant)
      assert Enum.empty?(records)
    end

    test "cannot create record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      record = Map.from_struct(record_same)

      refute Record.can_create?(actor, record)
    end

    test "cannot create record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      record = Map.from_struct(record_other)

      refute Record.can_create?(actor, record)
    end

    test "can bulk_import same import", %{actor: actor, import_same: import} do
      assert Record.can_bulk_import?(actor, import, %{})
    end

    test "can enqueue fast track checker", %{actor: actor, record_same: record_same} do
      assert Record.can_enqueue_fast_track_checker?(actor, record_same)
    end

    test "cannot update record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      refute Record.can_update?(actor, record_same)
    end

    test "cannot update record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      refute Record.can_update?(actor, record_other)
    end

    test "cannot destroy record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      refute Record.can_destroy?(actor, record_same)
    end

    test "cannot destroy record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      refute Record.can_destroy?(actor, record_other)
    end

    set_test_cases = [
      {:can_update?, "update"},
      {:can_set_imported?, "set_imported"},
      {:can_set_encoding?, "set_encoding"},
      {:can_set_encoded?, "set_encoded"},
      {:can_set_encoding_failed?, "set_encoding_failed"},
      {:can_enqueue_encoder?, "enqueue_encoder"},
      {:can_update_last_validation_started_at?, "update_last_validation_started_at"}
    ]

    for {method, method_description} <- set_test_cases do
      test "cannot #{method_description} for record with same institution", %{
        actor: actor,
        record_same: record_same
      } do
        refute apply(Record, unquote(method), [actor, record_same])
      end

      test "cannot #{method_description} for record with other institution", %{
        actor: actor,
        record_other: record_other
      } do
        refute apply(Record, unquote(method), [actor, record_other])
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

      import_same = Import.create!(collection_same, tenant: collection_same)

      record_same =
        record_fixture(%{
          collection: collection_same
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      record_other =
        record_fixture(%{
          collection: collection_other
        })

      [
        actor: actor,
        import_same: import_same,
        record_same: record_same,
        record_other: record_other,
        collection_same: collection_same,
        collection_other: collection_other
      ]
    end

    test "can read all", %{actor: actor, collection_same: tenant} do
      assert Record.can_read?(actor)

      records = Record.read!(actor: actor, tenant: tenant)
      assert length(records) == 1
    end

    test "cannot read from other collection", %{actor: actor, collection_other: tenant} do
      records = Record.read!(actor: actor, tenant: tenant)
      assert Enum.empty?(records)
    end

    test "can create record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      record =
        record_same
        |> Map.from_struct()
        |> Map.take([:tax_scientific_name, :mte_catalog_number, :collection])

      assert Record.can_create?(actor, record)
    end

    test "cannot create record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      record = Map.from_struct(record_other)

      refute Record.can_create?(actor, record)
    end

    test "can bulk_import same import", %{actor: actor, import_same: import} do
      assert Record.can_bulk_import?(actor, import, %{})
    end

    test "can enqueue fast track checker", %{actor: actor, record_same: record_same} do
      assert Record.can_enqueue_fast_track_checker?(actor, record_same)
    end

    test "can update record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      assert Record.can_update?(actor, record_same)
    end

    test "cannot update record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      refute Record.can_update?(actor, record_other)
    end

    test "can destroy record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      assert Record.can_destroy?(actor, record_same)
    end

    test "cannot destroy record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      refute Record.can_destroy?(actor, record_other)
    end

    set_test_cases = [
      {:can_update?, "update"},
      {:can_set_imported?, "set_imported"},
      {:can_set_encoding?, "set_encoding"},
      {:can_set_encoded?, "set_encoded"},
      {:can_set_encoding_failed?, "set_encoding_failed"},
      {:can_enqueue_encoder?, "enqueue_encoder"},
      {:can_update_last_validation_started_at?, "update_last_validation_started_at"}
    ]

    for {method, method_description} <- set_test_cases do
      test "can #{method_description} for record with same institution", %{
        actor: actor,
        record_same: record_same
      } do
        assert apply(Record, unquote(method), [actor, record_same])
      end

      test "cannot #{method_description} for record with other institution", %{
        actor: actor,
        record_other: record_other
      } do
        refute apply(Record, unquote(method), [actor, record_other])
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

      import_same = Import.create!(collection_same, tenant: collection_same)

      record_same =
        record_fixture(%{
          collection: collection_same
        })

      collection_other =
        collection_fixture(%{
          name: "Collection other",
          grscicoll_institution_key: @inst_2,
          grscicoll_reference: RestAPIStub.other_grscicoll_reference()
        })

      record_other =
        record_fixture(%{
          collection: collection_other
        })

      [
        actor: actor,
        import_same: import_same,
        record_same: record_same,
        record_other: record_other,
        collection_same: collection_same,
        collection_other: collection_other
      ]
    end

    test "can read all", %{actor: actor, collection_same: tenant} do
      assert Record.can_read?(actor)

      records = Record.read!(actor: actor, tenant: tenant)
      assert length(records) == 1
    end

    test "cannot read from other collection", %{actor: actor, collection_other: tenant} do
      records = Record.read!(actor: actor, tenant: tenant)
      assert Enum.empty?(records)
    end

    test "can create record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      record =
        record_same
        |> Map.from_struct()
        |> Map.take([:tax_scientific_name, :mte_catalog_number, :collection])

      assert Record.can_create?(actor, record)
    end

    test "cannot create record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      record = Map.from_struct(record_other)

      refute Record.can_create?(actor, record)
    end

    test "can bulk_import same import", %{actor: actor, import_same: import} do
      assert Record.can_bulk_import?(actor, import, %{})
    end

    test "can enqueue fast track checker", %{actor: actor, record_same: record_same} do
      assert Record.can_enqueue_fast_track_checker?(actor, record_same)
    end

    test "can update record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      assert Record.can_update?(actor, record_same)
    end

    test "cannot update record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      refute Record.can_update?(actor, record_other)
    end

    test "can destroy record with same institution", %{
      actor: actor,
      record_same: record_same
    } do
      assert Record.can_destroy?(actor, record_same)
    end

    test "cannot destroy record with other institution", %{
      actor: actor,
      record_other: record_other
    } do
      refute Record.can_destroy?(actor, record_other)
    end

    set_test_cases = [
      {:can_update?, "update"},
      {:can_set_imported?, "set_imported"},
      {:can_set_encoding?, "set_encoding"},
      {:can_set_encoded?, "set_encoded"},
      {:can_set_encoding_failed?, "set_encoding_failed"},
      {:can_enqueue_encoder?, "enqueue_encoder"},
      {:can_update_last_validation_started_at?, "update_last_validation_started_at"}
    ]

    for {method, method_description} <- set_test_cases do
      test "can #{method_description} for record with same institution", %{
        actor: actor,
        record_same: record_same
      } do
        assert apply(Record, unquote(method), [actor, record_same])
      end

      test "cannot #{method_description} for record with other institution", %{
        actor: actor,
        record_other: record_other
      } do
        refute apply(Record, unquote(method), [actor, record_other])
      end
    end
  end
end
