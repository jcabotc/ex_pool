defmodule ExPool.Pool.ManagerTest do
  use ExUnit.Case

  alias ExPool.Pool.Manager

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = Manager.new(worker_mod: TestWorker, size: 2)

    {:ok, %{state: state}}
  end

  test "#check_in and #check_out", %{state: state} do
    assert {:ok, {worker_1, state}} = Manager.check_out(state, :from_1)
    assert {:ok, {worker_2, state}} = Manager.check_out(state, :from_2)
    assert {:waiting, state}        = Manager.check_out(state, :from_3)

    assert {:check_out, {:from_3, state}} = Manager.check_in(state, worker_2)
    assert {:ok, _state}                  = Manager.check_in(state, worker_1)
  end
end
