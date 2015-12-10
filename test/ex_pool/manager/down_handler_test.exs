defmodule ExPool.Manager.DownHandlerTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.Manager.DownHandler

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker, size: 2)

    {:ok, %{state: state}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "process_down/2 when worker down", %{state: state} do
    {:ok, worker} = TestWorker.start_link
    worker_ref = Process.monitor(worker)

    pid = new_pid
    pid_ref = Process.monitor(pid)

    State.add_monitor(state, {:worker, worker}, worker_ref)
    State.add_monitor(state, {:in_use, worker}, pid_ref)

    assert {:dead_worker, state} = DownHandler.process_down(state, worker_ref)

    assert :not_found = State.ref_from_item(state, {:worker, worker})
    assert :not_found = State.ref_from_item(state, {:in_use, worker})
  end

  test "process_down/2 when using process down", %{state: state} do
    {:ok, worker} = TestWorker.start_link
    worker_ref = Process.monitor(worker)

    pid = new_pid
    pid_ref = Process.monitor(pid)

    State.add_monitor(state, {:worker, worker}, worker_ref)
    State.add_monitor(state, {:in_use, worker}, pid_ref)

    assert {:check_in, {^worker, state}} = DownHandler.process_down(state, pid_ref)

    assert :not_found = State.ref_from_item(state, {:in_use, worker})
  end

  test "process_down/2 when waiting process down", %{state: state} do
    pid = new_pid
    pid_ref = Process.monitor(pid)

    State.add_monitor(state, {:waiting, pid}, pid_ref)

    assert {:ok, state} = DownHandler.process_down(state, pid_ref)

    assert :not_found = State.ref_from_item(state, {:waiting, pid})
  end
end
