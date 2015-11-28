defmodule ExPool.Pool.State do
  @moduledoc """
  The internal state of a pool.

  It is a struct with the following fields:

    * `:worker_mod` - The worker module.
    * `:size` - Size of the pool
    * `:sup` - Pool supervisor
    * `:workers` - List of available worker processes
    * `:queue` - Waiting to store the waiting requests
  """

  alias ExPool.Pool.State.Workers
  alias ExPool.Pool.State.Waiting
  alias ExPool.Pool.State.Monitors

  @type t :: %__MODULE__{
    worker_mod: atom,
    size: non_neg_integer,
    sup: pid,
    workers: [pid],
    monitors: :ets.tid,
    waiting: any
  }
  defstruct [:worker_mod, :size,
             :sup, :workers, :monitors, :waiting]

  @default_size 5

  @doc """
  Creates a new pool state with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) The worker module. It has to fit in a
    supervision tree (like a GenServer).

    * `:size` - (Optional) The size of the pool (default #{@default_size}).

  """
  @spec new(config :: [Keyword]) :: State.t
  def new(config) do
    worker_mod = Keyword.fetch!(config, :worker_mod)
    size       = Keyword.get(config, :size, @default_size)

    %__MODULE__{worker_mod: worker_mod, size: size} |> start
  end

  # Workers
  @doc "Creates a new worker"
  @spec create_worker(State.t) :: {worker :: pid, State.t}
  def create_worker(state), do: Workers.create(state)

  @doc "Retrieve an available worker."
  @spec get_worker(State.t) :: {:ok, {pid, State.t}} | {:empty, State.t}
  def get_worker(state), do: Workers.get(state)

  @doc "Return a worker."
  @spec put_worker(State.t, pid) :: State.t
  def put_worker(state, worker), do: Workers.put(state, worker)

  # Waiting
  @doc "Adds an request to the waiting queue."
  @spec enqueue(State.t, from :: any) :: State.t
  def enqueue(state, from), do: Waiting.push(state, from)

  @doc "Pops a request from the waiting queue."
  @spec pop_from_queue(State.t) :: {:ok, {item :: any, State.t}} | {:empty, State.t}
  def pop_from_queue(state), do: Waiting.pop(state)

  # Monitors
  @doc "Monitors a worker"
  @spec watch(State.t, worker :: pid, tag :: atom, reference) :: State.t
  def watch(state, worker, tag, ref), do: Monitors.add(state, worker, tag, ref)

  @doc "Gets a worker from its reference"
  @spec pid_from_ref(State.t, reference) :: {:ok, {tag :: atom, pid}} | :not_found
  def pid_from_ref(state, reference), do: Monitors.pid_from_ref(state, reference)

  @doc "Demonitors a worker"
  @spec forget(State.t, worker :: pid, tag :: atom) :: State.t
  def forget(state, worker, tag), do: Monitors.forget(state, worker, tag)

  # Helpers
  defp start(state) do
    state
    |> Workers.setup
    |> Waiting.setup
    |> Monitors.setup
  end
end
