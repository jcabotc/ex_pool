defmodule ExPool.Integration.FaultTolerancyTest do
  use ExUnit.Case

  defmodule TestWorker do
    use GenServer

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, [])
    end

    def handle_call(step, _from, state) do
      if step in [3,6] do
        {:stop, :normal, state}
      else
        :timer.sleep(10)
        {:reply, {:done, step}, state}
      end
    end
  end

  @config worker_mod: TestWorker,
          name: :ex_pool_test_pool_name,
          size: 3

  setup do
    {:ok, pool} = ExPool.start_link(@config)

    {:ok, %{pool: pool}}
  end

  test "#run", %{pool: pool} do
    parent = self

    for step <- [1,2,3,4,5,6,7,8,9,10] do
      spawn fn ->
        result = ExPool.run pool, fn (worker) ->
          if step in [4,8,9] do
            exit(:normal)
          else
            GenServer.call(worker, step)
          end
        end

        send(parent, result)
      end
    end

    for step <- [1,2,5,7,10] do
      assert_receive {:done, ^step}
    end

    :timer.sleep(20)
    expected_info = %{workers: %{total: 3, free: 3, in_use: 0}, waiting: 0}
    assert ExPool.info(pool) == expected_info
  end
end
