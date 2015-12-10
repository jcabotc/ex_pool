defmodule ExPool.Manager.InfoTest do
  use ExUnit.Case

  alias ExPool.State
  alias ExPool.Manager.Info

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

  test "get/1", %{state: state} do
    expected_info = %{workers: %{total: 0, free: 0, in_use: 0}, waiting: 0}
    assert Info.get(state) == expected_info

    {worker, state} = State.create_worker(state)
    state = State.return_worker(state, worker)
    expected_info = %{workers: %{total: 1, free: 1, in_use: 0}, waiting: 0}
    assert Info.get(state) == expected_info

    {:ok, {_worker, state}} = State.get_worker(state)
    expected_info = %{workers: %{total: 1, free: 0, in_use: 1}, waiting: 0}
    assert Info.get(state) == expected_info

    state = State.enqueue(state, {:pid, :ref})
    expected_info = %{workers: %{total: 1, free: 0, in_use: 1}, waiting: 1}
    assert Info.get(state) == expected_info
  end
end
