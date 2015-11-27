defmodule ExPoolTest do
  use ExUnit.Case

  defmodule TestWorker do
    use GenServer

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, [])
    end

    def do_work(pid, milliseconds \\ 50) do
      GenServer.call(pid, milliseconds)
    end

    def handle_call(milliseconds, _from, state) do
      :timer.sleep(milliseconds)
      {:reply, {:work_done, milliseconds}, state}
    end
  end

  @config worker_mod: TestWorker,
          name: :ex_pool_test_pool_name,
          size: 2

  setup do
    {:ok, pool} = ExPool.start_link(@config)

    {:ok, %{pool: pool}}
  end

  test "#run", %{pool: pool} do
    assert {:work_done, 100} = ExPool.run(pool, &TestWorker.do_work(&1, 100))
    assert {:work_done, 5}   = ExPool.run(pool, &TestWorker.do_work(&1, 5))
    assert {:work_done, 5}   = ExPool.run(pool, &TestWorker.do_work(&1, 5))
    assert {:work_done, 5}   = ExPool.run(pool, &TestWorker.do_work(&1, 5))
    assert {:work_done, 5}   = ExPool.run(pool, &TestWorker.do_work(&1, 5))
    assert {:work_done, 5}   = ExPool.run(pool, &TestWorker.do_work(&1, 5))
    assert {:work_done, 5}   = ExPool.run(pool, &TestWorker.do_work(&1, 5))
  end
end
