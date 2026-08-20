defmodule DataAggregator.Collections.EncodingStatePollerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  import DataAggregator.RecordsFixtures
  import Ecto.Query

  alias DataAggregator.Records.Collection.Workers.EncodingStatePoller
  alias DataAggregator.Repo

  describe "start/1" do
    test "inserts a single tick per collection" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :encoding})

        assert %Oban.Job{id: id} = EncodingStatePoller.start(collection.id)
        assert %Oban.Job{id: ^id} = EncodingStatePoller.start(collection.id)

        assert poller_jobs(collection.id) === 1
      end)
    end
  end

  describe "schedule_next/2" do
    test "inserts a follow-up tick while the tick doing the scheduling is still executing" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :encoding})

        %Oban.Job{id: id} = EncodingStatePoller.start(collection.id)
        mark_executing(id)

        # `:executing` is part of the `:incomplete` unique group, so a unique
        # insert here would conflict with the job doing the scheduling and
        # silently halt the poller chain after a single tick.
        assert %Oban.Job{id: next_id} = EncodingStatePoller.schedule_next(collection.id, 10)

        refute next_id === id
        assert poller_jobs(collection.id) === 2
      end)
    end
  end

  defp mark_executing(id) do
    Repo.update_all(from(j in Oban.Job, where: j.id == ^id), set: [state: "executing"])
  end

  defp poller_jobs(collection_id) do
    Repo.aggregate(
      from(j in Oban.Job,
        where: j.worker == ^inspect(EncodingStatePoller),
        where: fragment("? ->> 'collection_id'", j.args) == ^to_string(collection_id)
      ),
      :count
    )
  end
end
