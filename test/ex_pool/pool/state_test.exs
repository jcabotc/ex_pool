defmodule ExPool.Pool.StateTest do
  use ExUnit.Case

  alias ExPool.Pool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 2)

    {:ok, %{state: state}}
  end

  test "#get_worker, #put_worker", %{state: state} do
    assert {:ok, {worker_1, state}}  = State.get_worker(state)
    assert {:ok, {_worker_2, state}} = State.get_worker(state)
    assert {:empty, ^state}          = State.get_worker(state)

    state = State.put_worker(state, worker_1)

    assert {:ok, {^worker_1, _state}} = State.get_worker(state)
  end

  test "#add_monitor, #get_pid, #get_monitor, #delete_monitor", %{state: state} do
    state = State.add_monitor(state, :pid_1, :ref_1)
    state = State.add_monitor(state, :pid_2, :ref_2)

    assert {:ok, :pid_2} = State.get_pid(state, :ref_2)
    assert {:ok, :ref_1} = State.get_ref(state, :pid_1)

    state = State.delete_monitor(state, :non_existent_pid)
    state = State.delete_monitor(state, :pid_1)

    assert :not_found = State.get_pid(state, :ref_1)
    assert :not_found = State.get_ref(state, :pid_1)
  end

  test "#enqueue, #pop_from_queue", %{state: state} do
    assert {:empty, state} = State.pop_from_queue(state)

    state = State.enqueue(state, :pid_1, :ref_1)
    state = State.enqueue(state, :pid_2, :ref_2)

    assert {:ok, {:pid_1, :ref_1, state}} = State.pop_from_queue(state)
    assert {:ok, {:pid_2, :ref_2, state}} = State.pop_from_queue(state)
    assert {:empty, _state}               = State.pop_from_queue(state)
  end
end
