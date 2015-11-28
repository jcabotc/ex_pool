defmodule ExPool.Pool.StateTest do
  use ExUnit.Case

  alias ExPool.Pool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 1)

    {:ok, %{state: state}}
  end

  test "#get_worker, #put_worker", %{state: state} do
    assert {:ok, {worker_1, state}}  = State.get_worker(state)
    assert {:empty, ^state}          = State.get_worker(state)

    state = State.put_worker(state, worker_1)
    assert {:ok, {^worker_1, _state}} = State.get_worker(state)
  end

  test "#enqueue, #pop_from_queue", %{state: state} do
    state = State.enqueue(state, :from)

    assert {:ok, {:from, state}} = State.pop_from_queue(state)
    assert {:empty, _state}      = State.pop_from_queue(state)
  end

  test "#watch, #worker_from_ref, #forget", %{state: state} do
    {:ok, {worker, state}} = State.get_worker(state)
    state                  = State.watch(state, worker)

    Agent.stop(worker)
    assert_receive {:DOWN, worker_ref, :process, _, _}

    assert ^worker = State.worker_from_ref(state, worker_ref)
    State.forget(state, worker)
  end
end
