defmodule ExPool.StateTest do
  use ExUnit.Case

  alias ExPool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 2)

    {:ok, %{state: state}}
  end

  test "stash", %{state: state} do
    assert 2 = State.size(state)

    assert {_worker, state}       = State.create_worker(state)
    assert {:ok, {worker, state}} = State.get_worker(state)
    assert 0                      = State.available_workers(state)

    state = State.return_worker(state, worker)
    assert 1 = State.available_workers(state)
  end

  test "monitors", %{state: state} do
    pid  = new_pid
    item = {:worker, pid}
    ref  = Process.monitor(pid)

    state = State.add_monitor(state, item, ref)
    assert {:ok, ^item} = State.item_from_ref(state, ref)
    assert {:ok, ^ref}  = State.ref_from_item(state, item)

    state = State.remove_monitor(state, item)
    assert :not_found = State.item_from_ref(state, ref)
    assert :not_found = State.item_from_ref(state, item)
  end
end
