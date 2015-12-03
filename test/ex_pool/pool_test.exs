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

    expected_info = %{workers: %{total: 2, in_use: 2, free: 0}, waiting: 1}
    assert expected_info == Pool.info(pool)

    assert :ok = Pool.check_in(pool, worker_2)
    assert_receive {:checked_out, ^worker_2}

    assert :ok       = Pool.check_in(pool, worker_1)
    assert ^worker_1 = Pool.check_out(pool)
  end

  test "fault tolerancy on worker crash", %{pool: pool} do
    worker = Pool.check_out(pool)
    Agent.stop(worker)

    assert Pool.check_out(pool) |> Process.alive?
    assert Pool.check_out(pool) |> Process.alive?
  end

  test "fault tolerancy on requester process crash when using the worker", %{pool: pool} do
    _worker_1 = Pool.check_out(pool)

    parent = self
    spawn fn ->
      worker_2 = Pool.check_out(pool)
      send(parent, {:checked_out, worker_2})
    end

    assert_receive {:checked_out, worker_2}
    assert ^worker_2 = Pool.check_out(pool)
  end

  test "fault tolerancy on requester process crash when it is waiting", %{pool: pool} do
    _worker_1 = Pool.check_out(pool)
    worker_2  = Pool.check_out(pool)

    pid = spawn fn -> Pool.check_out(pool) end
    Process.exit(pid, :kill)

    Pool.check_in(pool, worker_2)
    assert ^worker_2 = Pool.check_out(pool)
  end
end
