defmodule ExPool.StateTest do
  use ExUnit.Case

  alias ExPool.State

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 2)

    {:ok, %{state: state}}
  end

  test "stash interaction", %{state: state} do
    assert 2 = State.size(state)

    assert {_worker, state}       = State.create_worker(state)
    assert {:ok, {worker, state}} = State.get_worker(state)
    assert 0                      = State.available_workers(state)

    state = State.return_worker(state, worker)
    assert 1 = State.available_workers(state)
  end
end
