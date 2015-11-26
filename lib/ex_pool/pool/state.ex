defmodule ExPool.Pool.State do
  @moduledoc """
  The internal state of a pool.
  """

  alias ExPool.Pool.Supervisor, as: PoolSupervisor

  @type t :: %__MODULE__{
    worker_mod: atom,
    size: pos_integer,
    sup: pid,
    workers: [pid],
    monitors: any,
    queue: any
  }

  defstruct [:worker_mod, :size,
             :sup, :workers, :monitors, :queue]

  @default_size 5

  @doc """
  Creates a new pool state with the given configuration

  ## Configuration options

    * `:worker_mod` - The worker module. It has to fit in a supervision
      tree (like a GenServer).

    * `:size` - The size of the pool (default #{@default_size}).

  """
  @spec new(config :: [Keyword]) :: State.t
  def new(config) do
    worker_mod = Keyword.fetch!(config, :worker_mod)
    size       = Keyword.get(config, :size, @default_size)

    %__MODULE__{worker_mod: worker_mod, size: size} |> start
  end

  @doc """
  Get a worker and remove it from the workers list.
  """
  @spec get_worker(State.t) :: {:ok, {pid, State.t}} | {:empty, State.t}
  def get_worker(%{workers: []} = state) do
    {:empty, state}
  end
  def get_worker(%{workers: [worker|rest]} = state) do
    {:ok, {worker, %{state | workers: rest}}}
  end

  @doc """
  Add a worker to the workers list.
  """
  @spec get_worker(State.t) :: State.t
  def put_worker(%{workers: workers} = state, worker) do
    %{state | workers: [worker|workers]}
  end

  @doc """
  Add a ref for the given pid to the monitors list.
  """
  @spec add_monitor(State.t, pid, reference) :: State.t
  def add_monitor(%{monitors: monitors} = state, pid, ref) do
    :ets.insert(monitors, {pid, ref})
    state
  end

  @doc """
  Get a pid for the given ref from the monitors list.
  """
  @spec get_pid(State.t, reference) :: {:ok, pid} | :not_found
  def get_pid(%{monitors: monitors}, ref) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] -> {:ok, pid}
      []      -> :not_found
    end
  end

  @doc """
  Get a ref for the given pid from the monitors list.
  """
  @spec get_pid(State.t, pid) :: {:ok, reference} | :not_found
  def get_ref(%{monitors: monitors}, pid) do
    case :ets.lookup(monitors, pid) do
      [{^pid, ref}] -> {:ok, ref}
      []            -> :not_found
    end
  end

  @doc """
  Remove a pid (and its ref) from the monitors list.
  """
  @spec delete_monitor(State.t, pid) :: State.t
  def delete_monitor(%{monitors: monitors} = state, pid) do
    :ets.delete(monitors, pid)
    state
  end

  @doc """
  Adds a pair (pid, ref) to the queue.
  """
  @spec enqueue(State.t, pid, ref) :: State.t
  def enqueue(%{queue: queue} = state, pid, ref) do
    %{state | queue: :queue.in({pid, ref}, queue)}
  end

  @doc """
  Pops a pair (pid, ref) from the queue.
  """
  @spec pop_from_queue(State.t) :: {:ok, {pid, reference, State.t}} | {:empty, State.t}
  def pop_from_queue(%{queue: queue} = state) do
    case :queue.out(queue) do
      {{:value, {pid, ref}}, new_queue} -> {:ok, {pid, ref, %{state | queue: new_queue}}}
      {:empty, _queue}                  -> {:empty, state}
    end
  end

  defp start(state) do
    state |> create_resources |> prepopulate
  end

  defp create_resources(%{worker_mod: worker_mod} = state) do
    {:ok, sup} = PoolSupervisor.start_link(worker_mod)
    monitors   = :ets.new(:monitors, [:private])
    queue      = :queue.new

    %{state | sup: sup, monitors: monitors, queue: queue, workers: []}
  end

  defp prepopulate(%{size: size, sup: sup} = state) do
    workers = for _i <- 1..size, do: create_worker(sup)

    %{state | workers: workers}
  end

  def create_worker(sup) do
    {:ok, worker} = PoolSupervisor.start_child(sup)
    worker
  end
end
