defmodule ExPool.Pool.State.WaitingTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Waiting

  setup do
    state = %State{} |> Waiting.setup

    {:ok, %{state: state}}
  end

  test "#enqueue, #pop_from_queue", %{state: state} do
    assert {:empty, state} = Waiting.pop(state)

    state = Waiting.push(state, :from_1)
    state = Waiting.push(state, :from_2)

    assert {:ok, {:from_1, state}} = Waiting.pop(state)
    assert {:ok, {:from_2, state}} = Waiting.pop(state)
    assert {:empty, _state}        = Waiting.pop(state)
  end
end
