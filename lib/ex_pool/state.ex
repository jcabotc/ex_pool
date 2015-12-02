defmodule ExPool.State do
  @moduledoc """
  The internal state of a pool.

  It is a struct with the following fields:

    * `stash` - Stash of available workers
    * `monitors` - Store for the monitored references
    * `waiting` - Queue to store the waiting requests

  """

  alias ExPool.State
  alias ExPool.State.Stash

  @type stash  :: Stash.t
  @type worker :: Stash.worker

  @type t :: %__MODULE__{
    stash:    stash,
    monitors: :ets.tid,
    waiting:  any
  }

  defstruct stash:  nil,
            monitors: nil,
            waiting:  nil

  @doc """
  Creates a new pool state with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) The worker module. It has to fit in a
    supervision tree (like a GenServer).

    * `:size` - (Optional) The size of the pool (default 5).

  """
  @spec new(config :: [Keyword]) :: t
  def new(config) do
    stash = Stash.new(config)

    %State{stash: stash}
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
end
