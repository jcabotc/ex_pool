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

  alias ExPool.Pool.Workers
  alias ExPool.Pool.Waiting
  alias ExPool.Pool.Monitors

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

  @doc "Keeps on the waiting queue items that return true for the filter"
  @spec keep_on_queue(State.t, filter :: (any -> boolean)) :: State.t
  def keep_on_queue(state, filter), do: Waiting.keep(state, filter)

  @doc "Pops a request from the waiting queue."
  @spec pop_from_queue(State.t) :: {:ok, {item :: any, State.t}} | {:empty, State.t}
  def pop_from_queue(state), do: Waiting.pop(state)

  # Monitors
  @doc "Adds a item to monitors"
  @spec watch(State.t, item :: any, reference) :: State.t
  def watch(state, item, ref), do: Monitors.add(state, item, ref)

  @doc "Gets an item from its reference"
  @spec item_from_ref(State.t, reference) :: {:ok, item :: any} | :not_found
  def item_from_ref(state, ref), do: Monitors.item_from_ref(state, ref)

  @doc "Gets a reference from its item"
  @spec ref_from_item(State.t, item :: any) :: {:ok, reference} | :not_found
  def ref_from_item(state, item), do: Monitors.ref_from_item(state, item)

  @doc "Removes an item from monitors"
  @spec forget(State.t, item :: any) :: State.t
  def forget(state, item), do: Monitors.forget(state, item)

  # Helpers
  defp start(state) do
    state
    |> Workers.setup
    |> Waiting.setup
    |> Monitors.setup
  end
end
