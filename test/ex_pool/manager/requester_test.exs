defmodule ExPool.Manager.RequesterTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.Manager.Requester

  defmodule TestWorker do
    def start_link(_opts \\ []), do: Agent.start_link(fn -> :ok end)
  end

  setup do
    state = State.new(worker_mod: TestWorker)

    {:ok, %{state: state}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "request/2 with available workers", %{state: state} do
    pid  = new_pid
    from = {pid, :from_ref}

    {:ok, worker} = TestWorker.start_link
    state         = State.return_worker(state, worker)

    assert {:ok, {^worker, state}} = Requester.request(state, from)

    assert {:ok, _ref} = State.ref_from_item(state, {:in_use, worker})
  end

  test "request/2 with no available workers", %{state: state} do
    pid  = new_pid
    from = {pid, :from_ref}

    assert {:waiting, state} = Requester.request(state, from)

    assert {:ok, _ref}            = State.ref_from_item(state, {:waiting, pid})
    assert {:ok, {^from, _state}} = State.pop_from_queue(state)
  end
end
