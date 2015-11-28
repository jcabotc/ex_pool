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
  @doc "Retrieve an available worker."
  @spec get_worker(State.t) :: {:ok, {pid, State.t}} | {:empty, State.t}
  def get_worker(state), do: Workers.get(state)

  @doc "Return a worker."
  @spec put_worker(State.t, pid) :: State.t
  def put_worker(state, worker), do: Workers.put(state, worker)

  # Waiting
  @doc "Retrieve an available worker."
  @doc "Adds an request to the waiting queue."
  @spec enqueue(State.t, from :: any) :: State.t
  def enqueue(state, from), do: Waiting.push(state, from)

  @doc "Pops a request from the waiting queue."
  @spec pop_from_queue(State.t) :: {:ok, {item :: any, State.t}} | {:empty, State.t}
  def pop_from_queue(state), do: Waiting.pop(state)

  defp start(state) do
    state
    |> Workers.setup
    |> Waiting.setup
    |> prepopulate
  end

  defp prepopulate(%{size: size} = state) do
    prepopulate(state, size)
  end

  defp prepopulate(state, 0), do: state
  defp prepopulate(state, remaining) do
    state
    |> Workers.create
    |> prepopulate(remaining - 1)
  end
end
