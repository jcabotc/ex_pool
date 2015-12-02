defmodule ExPool.State do
  @moduledoc """
  The internal state of a pool.

  It is a struct with the following fields:

    * `stash` - Stash of available workers
    * `monitors` - Store for the monitored references
    * `queue` - Queue to store the waiting requests

  """

  alias ExPool.State

  alias ExPool.State.Stash
  alias ExPool.State.Monitors
  alias ExPool.State.Queue

  @type stash  :: Stash.t
  @type worker :: Stash.worker

  @type monitors :: Monitors.t
  @type item     :: Monitors.item
  @type ref      :: Monitors.ref

  @type queue :: Queue.t

  @type t :: %__MODULE__{
    stash:    stash,
    monitors: monitors,
    queue:    queue
  }

  defstruct stash:    nil,
            monitors: nil,
            queue:    nil

  @doc """
  Creates a new pool state with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) The worker module. It has to fit in a
    supervision tree (like a GenServer).

    * `:size` - (Optional) The size of the pool (default 5).

  """
  @spec new(config :: [Keyword]) :: t
  def new(config) do
    stash    = Stash.new(config)
    monitors = Monitors.new(config)
    queue    = Queue.new(config)

    %State{stash: stash, monitors: monitors, queue: queue}
  end

  ## Stash

  @doc """
  Returns the size of the pool.
  """
  @spec size(t) :: non_neg_integer
  def size(%State{stash: stash}), do: Stash.size(stash)

  @doc """
  Returns the number of available workers on the pool.
  """
  @spec available_workers(t) :: non_neg_integer
  def available_workers(%State{stash: stash}), do: Stash.available(stash)

  @doc """
  Creates a new available worker.
  """
  @spec create_worker(t) :: {worker, t}
  def create_worker(%State{stash: stash} = state) do
    {worker, new_stash} = Stash.create_worker(stash)
    {worker, %{state|stash: new_stash}}
  end

  @doc """
  Get a worker and remove it from the workers list.
  """
  @spec get_worker(t) :: {:ok, {worker, t}} | {:empty, t}
  def get_worker(%State{stash: stash} = state) do
    case Stash.get(stash) do
      {:ok, {worker, new_stash}} -> {:ok, {worker, %{state|stash: new_stash}}}
      {:empty, _stash}           -> {:empty, state}
    end
  end

  @doc """
  Add a worker to the workers list.
  """
  @spec return_worker(t, worker) :: t
  def return_worker(%State{stash: stash} = state, worker),
    do: %{state|stash: Stash.return(stash, worker)}

  ## Monitors

  @doc """
  Stores the given item and its associated reference.
  """
  @spec add_monitor(t, item, ref) :: t
  def add_monitor(%State{monitors: monitors} = state, item, ref) do
    monitors = Monitors.add(monitors, item, ref)
    %{state|monitors: monitors}
  end

  @doc """
  Gets an item from its reference.
  """
  @spec item_from_ref(t, ref) :: {:ok, item} | :not_found
  def item_from_ref(%State{monitors: monitors}, ref),
    do: Monitors.item_from_ref(monitors, ref)

  @doc """
  Gets a reference from its item.
  """
  @spec ref_from_item(t, item) :: {:ok, ref} | :not_found
  def ref_from_item(%State{monitors: monitors}, item),
    do: Monitors.ref_from_item(monitors, item)

  @doc """
  Removes the given item and its associated reference.
  """
  @spec remove_monitor(t, item) :: t
  def remove_monitor(%State{monitors: monitors} = state, item) do
    monitors = Monitors.forget(monitors, item)
    %{state|monitors: monitors}
  end

  ## Queue

  @doc """
  Returns the number of waiting processes.
  """
  @spec queue_size(t) :: non_neg_integer
  def queue_size(%State{queue: queue}), do: Queue.size(queue)

  @doc """
  Adds an item to the queue.
  """
  @spec enqueue(t, item) :: t
  def enqueue(%State{queue: queue} = state, item),
    do: %{state|queue: Queue.push(queue, item)}

  @doc """
  Removes an item from the queue.
  """
  @spec keep_on_queue(t, (item -> boolean)) :: t
  def keep_on_queue(%State{queue: queue} = state, filter),
    do: %{state|queue: Queue.keep(queue, filter)}

  @doc """
  Pops an item from the queue.
  """
  @spec pop_from_queue(t) :: {:ok, {item, t}} | {:empty, t}
  def pop_from_queue(%State{queue: queue} = state) do
    case Queue.pop(queue) do
      {:ok, {item, new_queue}} -> {:ok, {item, %{state|queue: new_queue}}}
      {:empty, _queue}         -> {:empty, state}
    end
  end
end
