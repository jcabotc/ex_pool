defmodule ExPool.Pool.State.MonitorsTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Pool.State.Monitors

  setup do
    state = %State{} |> Monitors.setup

    {:ok, %{state: state}}
  end

  test "#watch, #worker_from_ref, #forget", %{state: state} do
    {:ok, worker} = Agent.start_link(fn -> :ok end)

    state = Monitors.watch(state, worker)
    :ok   = Agent.stop(worker)

    assert_receive {:DOWN, worker_ref, :process, _, _}
    assert ^worker = Monitors.worker_from_ref(state, worker_ref)

    Monitors.forget(state, worker)
    assert catch_error Monitors.worker_from_ref(state, worker_ref)
  end
end
