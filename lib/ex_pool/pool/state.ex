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
    queue: any
  }

  defstruct [:worker_mod, :size,
             :sup, :workers, :queue]

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
  @spec put_worker(State.t, pid) :: State.t
  def put_worker(%{workers: workers} = state, worker) do
    %{state | workers: [worker|workers]}
  end

  @doc """
  Adds a pair (pid, ref) to the queue.
  """
  @spec enqueue(State.t, pid, reference) :: State.t
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
    queue      = :queue.new

    %{state | sup: sup, queue: queue, workers: []}
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
