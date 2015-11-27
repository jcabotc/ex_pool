defmodule ExPool do
  @moduledoc """
  Api for creating pools and running functions on them.

  Is recommended to always use blocking calls on workers
  (`GenServer.call` instead of `GenServer.cast`). Otherwise
  the transaction will finish and the worker may be returned
  to the pool before finishing its work.

  ## Example:

  ```elixir
  defmodule HardWorker do
    use GenServer

    def start_link(_opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, [])
    end

    def do_work(pid, seconds \\ 2) do
      GenServer.call(pid, seconds)
    end

    def handle_call(seconds, _from, state) do
      :timer.sleep(seconds)
      {:reply, :ok, state}
    end
  end

  {:ok, pool} = ExPool.start_link(worker_mod: HardWorker)

  ExPool.run(pool, &HardWorker.do_work(&1))

  ExPool.run pool, fn (worker) ->
    HardWorker.do_work(worker, 1)
    HardWorker.do_work(worker, 1)
  end
  ```
  """

  alias ExPool.Pool

  @doc """
  It starts a new pool with the given configuration.

  ## Options:

    * :worker_mod - (Required) Worker module for the pool.

    * :size - (Optional) Size of the pool (default 5).

    * :name - (Optional) Name of the pool GenServer.

  """
  @spec start_link(opts :: [Keyword]) :: Supervisor.on_start
  def start_link(opts \\ []) do
    Pool.start_link(opts)
  end

  @doc """
  Runs the function with a worker from the given pool.

  The function must receive the worker pid as its only argument.
  """
  @spec run(pool :: (atom | pid), fun) :: any
  def run(pool, func) do
    worker = Pool.check_out(pool)

    try do
      func.(worker)
    after
      worker = Pool.check_in(pool, worker)
    end
  end
end
