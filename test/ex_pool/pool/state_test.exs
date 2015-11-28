defmodule ExPool.Pool.StateTest do
  use ExUnit.Case

  alias ExPool.Pool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker)

    {:ok, %{state: state}}
  end

  test "#create_worker, #get_worker, #put_worker", %{state: state} do
    {_worker, state} = State.create_worker(state)

    assert {:ok, {worker_1, state}}  = State.get_worker(state)
    assert {:empty, ^state}          = State.get_worker(state)

    {_worker, state} = State.create_worker(state)
    assert {:ok, {_worker_2, state}}  = State.get_worker(state)

    state = State.put_worker(state, worker_1)
    assert {:ok, {^worker_1, _state}} = State.get_worker(state)
  end

  test "#enqueue, #pop_from_queue", %{state: state} do
    state = State.enqueue(state, :from)

    assert {:ok, {:from, state}} = State.pop_from_queue(state)
    assert {:empty, _state}      = State.pop_from_queue(state)
  end

  test "#add, #item_from_ref, #forget", %{state: state} do
    worker = TestWorker.start_link

    state = State.watch(state, {:worker, worker}, :ref)

    assert {:ok, {:worker, ^worker}} = State.item_from_ref(state, :ref)
    assert {:ok, :ref}               = State.ref_from_item(state, {:worker, worker})

    State.forget(state, {:worker, worker})
    assert :not_found = State.item_from_ref(state, :ref)
  end
end
