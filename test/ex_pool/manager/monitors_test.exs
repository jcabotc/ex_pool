defmodule ExPool.Manager.MonitorsTest do
  use ExUnit.Case

  alias ExPool.Pool.State
  alias ExPool.Manager.Monitors

  setup do
    state = %State{} |> Monitors.setup

    {:ok, %{state: state}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "#add, #item_from_ref, #forget", %{state: state} do
    worker = new_pid

    state  = Monitors.add(state, {:worker, worker}, :ref_1)
    state  = Monitors.add(state, {:in_use, worker}, :ref_2)

    assert {:ok, {:in_use, ^worker}} = Monitors.item_from_ref(state, :ref_2)
    assert {:ok, {:worker, ^worker}} = Monitors.item_from_ref(state, :ref_1)

    assert {:ok, :ref_2} = Monitors.ref_from_item(state, {:in_use, worker})
    assert {:ok, :ref_1} = Monitors.ref_from_item(state, {:worker, worker})

    state = Monitors.forget(state, {:in_use, worker})
    assert :not_found = Monitors.item_from_ref(state, :ref_2)
    assert :not_found = Monitors.ref_from_item(state, {:in_use, worker})
  end
end
