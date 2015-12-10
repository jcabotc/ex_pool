defmodule ExPool.Manager.PopulatorTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.Manager.Populator

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 2)

    {:ok, %{state: state}}
  end

  test "populate/1", %{state: state} do
    assert {workers, state} = Populator.populate(state)

    assert State.total_workers(state) == 2

    Enum.each workers, fn (worker) ->
      assert {:ok, _ref} = State.ref_from_item(state, {:worker, worker})
    end
  end

  test "add/1", %{state: state} do
    assert {worker, state} = Populator.add(state)

    assert State.total_workers(state) == 1
    assert {:ok, _ref} = State.ref_from_item(state, {:worker, worker})
  end
end
