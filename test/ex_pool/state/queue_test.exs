defmodule ExPool.State.QueueTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.State.Queue

  setup do
    state = %State{} |> Queue.setup

    {:ok, %{state: state}}
  end

  test "#enqueue, #count, #pop_from_queue", %{state: state} do
    assert {:empty, state} = Queue.pop(state)

    state = Queue.push(state, :from_1)
    state = Queue.push(state, :from_2)

    assert 2 = Queue.count(state)

    assert {:ok, {:from_1, state}} = Queue.pop(state)
    assert {:ok, {:from_2, state}} = Queue.pop(state)
    assert {:empty, _state}        = Queue.pop(state)

    assert 0 = Queue.count(state)
  end

  test "#remove", %{state: state} do
    state = state
            |> Queue.push(:from_1)
            |> Queue.push(:from_2)
            |> Queue.push(:from_1)
            |> Queue.keep(&(&1 != :from_1))

    assert {:ok, {:from_2, state}} = Queue.pop(state)
    assert {:empty, _state}        = Queue.pop(state)
  end
end
