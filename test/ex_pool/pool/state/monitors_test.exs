defmodule ExPool.Pool.State.MonitorsTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Monitors

  setup do
    state = %State{} |> Monitors.setup

    {:ok, %{state: state}}
  end

  test "#watch, #worker_from_ref on fail", %{state: state} do
    {:ok, worker} = Agent.start_link(fn -> :ok end)

    state = Monitors.watch(state, worker)
    :ok   = Agent.stop(worker)

    assert_receive {:DOWN, worker_ref, :process, _, _}
    assert ^worker = Monitors.worker_from_ref(state, worker_ref)
  end

  test "#watch, #forget with no fail", %{state: state} do
    {:ok, worker} = Agent.start_link(fn -> :ok end)

    state  = Monitors.watch(state, worker)
    _state = Monitors.forget(state, worker)
    :ok    = Agent.stop(worker)

    refute_receive {:DOWN, _, :process, _, _}
  end
end
