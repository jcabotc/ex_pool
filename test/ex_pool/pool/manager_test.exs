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
    assert {:ok, {worker_1, state}} = Manager.check_out(state, :request_1)
    assert {:ok, {worker_2, state}} = Manager.check_out(state, :request_2)
    assert {:waiting, state}        = Manager.check_out(state, :request_3)

    assert {:check_out, {:request_3, ^worker_2, state}} = Manager.check_in(state, worker_2)
    assert {:ok, _state}                                = Manager.check_in(state, worker_1)
  end

  test "crash and #process_down", %{state: state} do
    assert {:ok, {worker_1, state}} = Manager.check_out(state, :request_1)
    Agent.stop(worker_1)

    assert_receive {:DOWN, ref, :process, _, _}
    state = Manager.process_down(state, ref)

    assert {:ok, {worker_2, state}} = Manager.check_out(state, :request_2)
    assert Process.alive?(worker_2)
    assert {:ok, {worker_3, state}} = Manager.check_out(state, :request_3)
    assert Process.alive?(worker_3)
    assert {:waiting, _state} = Manager.check_out(state, :request_4)
  end
end
