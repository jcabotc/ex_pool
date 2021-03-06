defmodule ExPool.Pool do
  @moduledoc """
  Pool GenServer.

  It provides an interface to start a pool, check in and check out workers.

  ```elixir
  alias ExPool.Pool

  # Starts a new pool
  {:ok, pool} = Pool.start_link(config)

  # Blocks until there is a worker available
  worker = Pool.check_out(pool)

  # do some work with the worker

  # Returns the worker to the pool
  :ok = Pool.check_in(pool, worker)
  ```
  """

  use GenServer

  alias ExPool.Manager

  @doc """
  Starts a new pool GenServer.

  ## Options:

    * :name - (Optional) The name of the pool

    * The rest of the options will be passed to the internal
    state as pool configuration (for more information about the
    available options check ExPool.Pool.State.new/1).

  """
  @spec start_link(opts :: [Keyword]) :: Supervisor.on_start
  def start_link(opts \\ []) do
    name_opts = Keyword.take(opts, [:name])

    GenServer.start_link(__MODULE__, opts, name_opts)
  end

  @doc """
  Get information about the current state of the pool.
  """
  @spec info(pool :: pid) :: map
  def info(pool) do
    GenServer.call(pool, :info)
  end

  @doc """
  Retrieve a worker from the pool.

  If there aren't any available workers it blocks until one is available.
  """
  @spec check_out(pool :: pid) :: worker :: pid
  def check_out(pool) do
    GenServer.call(pool, :check_out)
  end

  @doc """
  Returns a worker into the pool to be used by other processes.
  """
  @spec check_in(pool :: pid, worker :: pid) :: :ok
  def check_in(pool, worker) do
    GenServer.cast(pool, {:check_in, worker})
  end

  @doc false
  def init(config) do
    state = Manager.new(config)

    {:ok, state}
  end

  @doc false
  def handle_call(:check_out, from, state) do
    case Manager.check_out(state, from) do
      {:ok, {worker, new_state}} -> {:reply, worker, new_state}
      {:waiting, new_state}      -> {:noreply, new_state}
    end
  end

  @doc false
  def handle_call(:info, _from, state) do
    info = Manager.info(state)

    {:reply, info, state}
  end

  @doc false
  def handle_cast({:check_in, worker}, state) do
    state = state
            |> Manager.check_in(worker)
            |> handle_possible_checkout

    {:noreply, state}
  end

  @doc false
  def handle_info({:DOWN, ref, :process, _obj, _reason}, state) do
    state = state
            |> Manager.process_down(ref)
            |> handle_possible_checkout

    {:noreply, state}
  end

  defp handle_possible_checkout({:check_out, {from, worker, state}}) do
    GenServer.reply(from, worker)
    state
  end

  defp handle_possible_checkout({:ok, state}) do
    state
  end
end
