defmodule ExPool.State.MonitorsTest do
  use ExUnit.Case

  alias ExPool.State.Monitors

  setup do
    monitors = Monitors.new([])

    {:ok, %{monitors: monitors}}
  end

  def new_pid do
    {:ok, pid} = Agent.start_link(fn -> :ok end)
    pid
  end

  test "#add, #item_from_ref, #forget", %{monitors: monitors} do
    worker = new_pid

    monitors = Monitors.add(monitors, {:worker, worker}, :ref_1)
    monitors = Monitors.add(monitors, {:in_use, worker}, :ref_2)

    assert {:ok, {:in_use, ^worker}} = Monitors.item_from_ref(monitors, :ref_2)
    assert {:ok, {:worker, ^worker}} = Monitors.item_from_ref(monitors, :ref_1)

    assert {:ok, :ref_2} = Monitors.ref_from_item(monitors, {:in_use, worker})
    assert {:ok, :ref_1} = Monitors.ref_from_item(monitors, {:worker, worker})

    monitors = Monitors.forget(monitors, {:in_use, worker})
    assert :not_found = Monitors.item_from_ref(monitors, :ref_2)
    assert :not_found = Monitors.ref_from_item(monitors, {:in_use, worker})
  end
end
