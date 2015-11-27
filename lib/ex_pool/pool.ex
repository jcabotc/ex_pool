defmodule ExPool.Pool do
  @moduledoc """
  Pool
  """

  alias ExPool.Pool.Manager

  use GenServer

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
  Check-out a worker from the pool. It blocks until one is available.
  """
  @spec check_out(pool :: pid) :: worker :: pid
  def check_out(pool) do
    GenServer.call(pool, :check_out)
  end

  @doc """
  Check-in a worker into the pool.
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
  def handle_cast({:check_in, worker}, state) do
    new_state = state
                |> Manager.check_in(worker)
                |> handle_check_in

    {:noreply, new_state}
  end

  defp handle_check_in({:ok, state}) do
    state
  end
  defp handle_check_in({:check_out, {from, worker, state}}) do
    GenServer.reply(from, worker)
    state
  end
end
