defmodule ExPool.Pool.State.MonitorsTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Monitors

  setup do
    state = %State{} |> Monitors.setup

    {:ok, %{state: state}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "#add, #pid_from_ref, #forget", %{state: state} do
    worker = new_pid

    state  = Monitors.add(state, {:worker, worker}, :ref_1)
    state  = Monitors.add(state, {:in_use, worker}, :ref_2)

    assert {:ok, {:in_use, ^worker}} = Monitors.pid_from_ref(state, :ref_2)
    assert {:ok, {:worker, ^worker}} = Monitors.pid_from_ref(state, :ref_1)

    state = Monitors.forget(state, {:in_use, worker})
    assert :not_found = Monitors.pid_from_ref(state, :ref_2)
  end
end
