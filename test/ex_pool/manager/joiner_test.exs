defmodule ExPool.Manager.JoinerTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.Manager.Joiner

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 2)
    {:ok, worker} = TestWorker.start_link

    {:ok, %{worker: worker, state: state}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "join/2 with a dead worker", %{worker: worker, state: state} do
    ref = Process.monitor(worker)
    state = State.add_monitor(state, {:worker, worker}, ref)

    Agent.stop(worker)

    assert {:dead_worker, ^state} = Joiner.join(state, worker)

    assert :not_found = State.ref_from_item(state, {:worker, worker})
  end

  test "join/2 with a process waiting", %{worker: worker, state: state} do
    pid  = new_pid
    from = {pid, :from_ref}
    ref  = Process.monitor(pid)

    state = State.enqueue(state, from)
    state = State.add_monitor(state, {:waiting, pid}, ref)

    assert {:check_out, {^from, ^worker, state}} = Joiner.join(state, worker)

    assert :not_found = State.ref_from_item(state, {:waiting, pid})
    assert {:ok, ^ref} = State.ref_from_item(state, {:in_use, worker})
    assert State.available_workers(state) == 0
  end

  test "join/2 with no process waiting", %{worker: worker, state: state} do
    pid = new_pid
    ref = Process.monitor(pid)

    state = State.add_monitor(state, {:in_use, worker}, ref)

    assert {:ok, state} = Joiner.join(state, worker)

    assert :not_found = State.ref_from_item(state, {:in_use, worker})
    assert State.available_workers(state) == 1
  end
end
