defmodule DataAggregator.Bench do
  @moduledoc """
  Shared helpers for the bench harness: stub install, measurement, result
  recording, and bench-specific user/collection bootstrap.
  """

  import Ecto.Query, only: [from: 2]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Bench.LatencyShim
  alias DataAggregator.Bench.LatencyShims
  alias DataAggregator.CatalogOfLife
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Collection

  require Ash.Query

  @grscicoll_reference "322ce107-3156-4420-8a2b-7f17efeaa472"
  @user_email "bench+admin@example.com"

  @stubs [
    {Gbif.RestAPI, Gbif.RestAPIStub, LatencyShims.Gbif},
    {Opencage.RestAPI, Opencage.RestAPIStub, LatencyShims.Opencage},
    {CatalogOfLife.RestAPI, CatalogOfLife.RestAPIStub, LatencyShims.CatalogOfLife}
  ]

  @poll_ms 50

  def grscicoll_reference, do: @grscicoll_reference

  def install_stubs do
    Enum.each(@stubs, fn {target, _, _} -> Mimic.copy(target) end)
    Mimic.set_mimic_global()
    wrap? = LatencyShim.enabled?()

    Enum.each(@stubs, fn {target, plain, latency} ->
      Mimic.stub_with(target, if(wrap?, do: latency, else: plain))
    end)
  end

  def user! do
    case Ash.read(Ash.Query.filter(User, email == ^@user_email),
           domain: DataAggregator.Accounts,
           authorize?: false
         ) do
      {:ok, [user | _]} ->
        user

      _ ->
        User.register_with_password!(%{
          first_name: "Bench",
          last_name: "Admin",
          email: @user_email,
          password: "secret42",
          terms_accepted_at: DateTime.utc_now(),
          roles: ["admin", "collection_administrator", "data_digitizer"]
        })
    end
  end

  def collection! do
    case Collection.get_by_grscicoll_reference(@grscicoll_reference) do
      {:ok, collection} ->
        collection

      _ ->
        Collection.create!(%{
          type: :zoology,
          name: "bench-collection",
          owner: "Bench",
          grscicoll_reference: @grscicoll_reference
        })
    end
  end

  def measure(queues, timeout_ms, fun) do
    t0 = System.monotonic_time(:millisecond)
    fun.()
    t1 = System.monotonic_time(:millisecond)
    drained? = wait_for_queues(queues, timeout_ms)
    t2 = System.monotonic_time(:millisecond)
    %{wall_ms: t2 - t0, trigger_ms: t1 - t0, drain_ms: t2 - t1, drained?: drained?}
  end

  def wait_for_queues([], _), do: true

  def wait_for_queues(queues, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_wait(queues, deadline)
  end

  defp do_wait(queues, deadline) do
    cond do
      pending(queues) == 0 ->
        true

      System.monotonic_time(:millisecond) > deadline ->
        false

      true ->
        Process.sleep(@poll_ms)
        do_wait(queues, deadline)
    end
  end

  defp pending(queues) do
    names = Enum.map(queues, &to_string/1)

    DataAggregator.Repo.aggregate(
      from(j in "oban_jobs",
        where: j.queue in ^names and j.state in ~w(available scheduled executing retryable)
      ),
      :count,
      :id
    )
  end

  def new_results_file do
    File.mkdir_p!("bench/results")
    stamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic) |> String.replace(~r/[^0-9TZ]/, "")
    Path.join("bench/results", "#{stamp}-#{git_sha()}.jsonl")
  end

  def record(path, scenario, size, measurement, extra \\ %{}) do
    entry =
      %{
        ts: DateTime.to_iso8601(DateTime.utc_now()),
        git_sha: git_sha(),
        branch: git_branch(),
        size: size,
        scenario: scenario
      }
      |> Map.merge(measurement)
      |> Map.merge(extra)

    File.write!(path, Jason.encode!(entry) <> "\n", [:append])
    entry
  end

  defp git_sha, do: git("rev-parse", ["--short", "HEAD"])
  defp git_branch, do: git("rev-parse", ["--abbrev-ref", "HEAD"])

  defp git(cmd, args) do
    case System.cmd("git", [cmd | args], stderr_to_stdout: true) do
      {out, 0} -> String.trim(out)
      _ -> "unknown"
    end
  end
end
