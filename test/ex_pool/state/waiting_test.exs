defmodule ExPool.State.WaitingTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.State.Waiting

  setup do
    state = %State{} |> Waiting.setup

    {:ok, %{state: state}}
  end

  test "#enqueue, #count, #pop_from_queue", %{state: state} do
    assert {:empty, state} = Waiting.pop(state)

    state = Waiting.push(state, :from_1)
    state = Waiting.push(state, :from_2)

    assert 2 = Waiting.count(state)

    assert {:ok, {:from_1, state}} = Waiting.pop(state)
    assert {:ok, {:from_2, state}} = Waiting.pop(state)
    assert {:empty, _state}        = Waiting.pop(state)

    assert 0 = Waiting.count(state)
  end

  test "#remove", %{state: state} do
    state = state
            |> Waiting.push(:from_1)
            |> Waiting.push(:from_2)
            |> Waiting.push(:from_1)
            |> Waiting.keep(&(&1 != :from_1))

    assert {:ok, {:from_2, state}} = Waiting.pop(state)
    assert {:empty, _state}        = Waiting.pop(state)
  end
end
