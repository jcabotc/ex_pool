defmodule ExPoolTest do
  use ExUnit.Case

  defmodule TestWorker do
    use GenServer

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, [])
    end

    def handle_call(milliseconds, _from, state) do
      :timer.sleep(milliseconds)
      {:reply, {:work_done, milliseconds}, state}
    end
  end

  @config worker_mod: TestWorker,
          name: :ex_pool_test_pool_name,
          size: 3

  setup do
    {:ok, pool} = ExPool.start_link(@config)

    {:ok, %{pool: pool}}
  end

  @work_times [30, 20, 20, 5, 15, 5, 15, 10, 10, 20, 5, 30]

  # test "#run", %{pool: pool} do
  #   parent = self
  #
  #   for time <- @work_times do
  #     spawn fn ->
  #       result = ExPool.run(pool, &GenServer.call(&1, time))
  #       send(parent, result)
  #     end
  #   end
  #
  #   for time <- @work_times do
  #     assert_receive {:work_done, ^time}
  #   end
  # end
end
