defmodule ExPool.PoolTest do
  use ExUnit.Case

  defmodule TestWorker do
    def start_link(_ \\ []), do: Agent.start_link(fn -> :ok end)
  end

  alias ExPool.Pool

  setup do
    {:ok, pool} = Pool.start_link(worker_mod: TestWorker, size: 2)

    {:ok, %{pool: pool}}
  end

  test "#check_out and #check_in", %{pool: pool} do
    worker_1 = Pool.check_out(pool)
    worker_2 = Pool.check_out(pool)

    parent = self
    spawn_link fn ->
      worker = Pool.check_out(pool)
      send(parent, {:checked_out, worker})
    end

    refute_receive {:checked_out, _worker}

    assert :ok = Pool.check_in(pool, worker_2)
    assert_receive {:checked_out, ^worker_2}

    assert :ok       = Pool.check_in(pool, worker_1)
    assert ^worker_1 = Pool.check_out(pool)
  end
end
