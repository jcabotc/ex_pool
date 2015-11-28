defmodule ExPool.Pool.State.QueueTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Queue

  setup do
    state = %State{} |> Queue.setup

    {:ok, %{state: state}}
  end

  test "#enqueue, #pop_from_queue", %{state: state} do
    assert {:empty, state} = Queue.pop(state)

    state = Queue.push(state, :from_1)
    state = Queue.push(state, :from_2)

    assert {:ok, {:from_1, state}} = Queue.pop(state)
    assert {:ok, {:from_2, state}} = Queue.pop(state)
    assert {:empty, _state}        = Queue.pop(state)
  end
end
