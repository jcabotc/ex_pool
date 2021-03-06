defmodule ExPool.ManagerTest do
  use ExUnit.Case

  alias ExPool.Manager

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = Manager.new(worker_mod: TestWorker, size: 1)

    {:ok, %{state: state}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "#check_in, #check_out, #info", %{state: state} do
    {pid_1, pid_2} = {new_pid, new_pid}

    assert {:ok, {worker_1, state}} = Manager.check_out(state, {pid_1, :ref_1})
    assert {:waiting, state}        = Manager.check_out(state, {pid_2, :ref_2})

    expected_info = %{workers: %{total: 1, in_use: 1, free: 0}, waiting: 1}
    assert expected_info == Manager.info(state)

    assert {:check_out, {{^pid_2, :ref_2}, ^worker_1, state}} = Manager.check_in(state, worker_1)
    assert {:ok, _state}                                      = Manager.check_in(state, worker_1)
  end

  test "worker crash and #process_down", %{state: state} do
    {pid_1, pid_2, pid_3} = {new_pid, new_pid, new_pid}

    assert {:ok, {worker_1, state}} = Manager.check_out(state, {pid_1, :ref_1})
    Agent.stop(worker_1)

    assert_receive {:DOWN, ref, :process, _, _}
    {:ok, state} = Manager.process_down(state, ref)

    assert {:ok, {worker_2, state}} = Manager.check_out(state, {pid_2, :ref_2})
    assert Process.alive?(worker_2)
    assert {:waiting, _state} = Manager.check_out(state, {pid_3, :ref_3})
  end

  test "client crash while using the worker #process_down", %{state: state} do
    {pid_1, pid_2} = {new_pid, new_pid}

    assert {:ok, {_worker_1, state}} = Manager.check_out(state, {pid_1, :ref_1})

    Agent.stop(pid_1)
    assert_receive {:DOWN, ref, :process, _, _}

    {:ok, state} = Manager.process_down(state, ref)

    assert {:ok, {_worker_2, _state}} = Manager.check_out(state, {pid_2, :ref_2})
  end

  test "client crash while waiting for a worker #process_down", %{state: state} do
    {pid_1, pid_2, pid_3} = {new_pid, new_pid, new_pid}

    assert {:ok, {worker_1, state}} = Manager.check_out(state, {pid_1, :ref_1})
    assert {:waiting, state}        = Manager.check_out(state, {pid_2, :ref_2})

    Agent.stop(pid_2)
    assert_receive {:DOWN, ref, :process, _, _}

    {:ok, state} = Manager.process_down(state, ref)
    assert {:waiting, state} = Manager.check_out(state, {pid_3, :ref_3})

    assert {:check_out, {{^pid_3, :ref_3}, ^worker_1, _state}} = Manager.check_in(state, worker_1)
  end
end
