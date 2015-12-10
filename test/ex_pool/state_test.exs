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

  test "config", %{state: state} do
    assert 2 = State.size(state)
  end

  test "factory", %{state: state} do
    {worker_1, state} = State.create_worker(state)
    {worker_2, state} = State.create_worker(state)
    assert State.total_workers(state) == 2

    Agent.stop(worker_1)
    state = State.report_dead_worker(state)
    state = State.destroy_worker(state, worker_2)
    assert State.total_workers(state) == 0
  end

  test "stash", %{state: state} do
    {:ok, worker} = TestWorker.start_link

    state = State.return_worker(state, worker)
    assert 1 = State.available_workers(state)

    assert {:ok, {_worker, state}} = State.get_worker(state)
    assert 0 = State.available_workers(state)
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

  test "queue", %{state: state} do
    item_1 = :an_item
    item_2 = :another_item

    state = State.enqueue(state, item_1)
    state = State.enqueue(state, item_2)
    assert 2 = State.queue_size(state)

    state = State.keep_on_queue(state, &(&1 == :an_item))
    assert 1 = State.queue_size(state)

    assert {:ok, {:an_item, _state}} = State.pop_from_queue(state)
  end
end
