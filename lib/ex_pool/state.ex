defmodule ExPool.State do
  @moduledoc """
  The internal state of the pool.

  This module defines a `ExPool.State` struct and the main functions
  for working with pool internal state.

  ## Fields

    * `stash` - stash of available workers
    * `monitors` - store for the monitored references
    * `queue` - queue to store the waiting requests

  """

  alias ExPool.State

  alias ExPool.State.Config
  alias ExPool.State.Factory
  alias ExPool.State.Stash
  alias ExPool.State.Monitors
  alias ExPool.State.Queue

  @type config :: Config.t

  @type factory :: Factory.t

  @type stash  :: Stash.t
  @type worker :: Stash.worker

  @type monitors :: Monitors.t
  @type item     :: Monitors.item
  @type ref      :: Monitors.ref

  @type queue :: Queue.t

  @type t :: %__MODULE__{
    config:   config,
    factory:  factory,
    stash:    stash,
    monitors: monitors,
    queue:    queue
  }

  defstruct config:   nil,
            factory:  nil,
            stash:    nil,
            monitors: nil,
            queue:    nil

  @doc """
  Creates a new pool state with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) The worker module. It has to fit in a
    supervision tree (like a GenServer).

    * `:size` - (Optional) The size of the pool (default 5).

  """
  @spec new(opts :: [Keyword]) :: t
  def new(opts) do
    %State{
      config:   Config.new(opts),
      factory:  Factory.new(opts),
      stash:    Stash.new(opts),
      monitors: Monitors.new(opts),
      queue:    Queue.new(opts)
    }
  end

  ## Config

  @doc """
  Returns the total number of workers.
  """
  @spec size(t) :: non_neg_integer
  def size(%State{config: config}), do: config.size

  ## Factory

  @spec create_worker(t) :: {worker, t}
  def create_worker(%State{factory: factory} = state) do
    {worker, factory} = Factory.create(factory)
    {worker, %{state|factory: factory}}
  end

  @spec total_workers(t) :: non_neg_integer
  def total_workers(%State{factory: factory}), do: factory.total

  @spec destroy_worker(t, worker) :: t
  def destroy_worker(%State{factory: factory} = state, worker),
    do: %{state|factory: Factory.destroy(factory, worker)}

  @spec report_dead_worker(t) :: t
  def report_dead_worker(%State{factory: factory} = state),
    do: %{state|factory: Factory.report_death(factory)}

  ## Stash

  @doc """
  Returns the number of available workers.
  """
  @spec available_workers(t) :: non_neg_integer
  def available_workers(%State{stash: stash}), do: Stash.available(stash)

  @doc """
  Gets a worker from the pool if there is any available.
  """
  @spec get_worker(t) :: {:ok, {worker, t}} | {:empty, t}
  def get_worker(%State{stash: stash} = state) do
    case Stash.get(stash) do
      {:ok, {worker, new_stash}} -> {:ok, {worker, %{state|stash: new_stash}}}
      {:empty, _stash}           -> {:empty, state}
    end
  end

  @doc """
  Returns a worker to the pool.
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
  Keeps on the queue only items for those the function is true.
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
