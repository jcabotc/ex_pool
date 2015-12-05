defmodule ExPool.State.Stash do
  @moduledoc """
  A stash of workers.

  This module defines a `ExPool.State.Stash` struct and the main functions
  to manage workers in a pool.

  ## Fields

    * `sup` - simple_one_for_one supervisor to start and supervise workers
    * `workers` - list of available workers

  """

  @type worker :: pid

  @type sup     :: pid
  @type workers :: [worker]

  @type t :: %__MODULE__{
    sup:     sup,
    workers: workers,
  }

  defstruct sup:     nil,
            workers: []

  alias ExPool.State.Stash
  alias ExPool.State.Factory.Supervisor, as: StashSupervisor

  @doc """
  Builds a new Stash struct with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) worker module that fits on a supervision tree

  """
  @spec new(opts :: [Keyword]) :: t
  def new(opts) do
    worker_mod = Keyword.fetch!(opts, :worker_mod)
    {:ok, sup} = StashSupervisor.start_link(worker_mod)

    %Stash{sup: sup}
  end

  @doc """
  Returns the number of available workers.
  """
  @spec available(t) :: non_neg_integer
  def available(%Stash{workers: workers}), do: length(workers)

  @doc """
  Creates a new worker.
  """
  @spec create_worker(t) :: {worker, t}
  def create_worker(%Stash{sup: sup, workers: workers} = stash) do
    {:ok, worker} = StashSupervisor.start_child(sup)

    {worker, %{stash | workers: [worker|workers]}}
  end

  @doc """
  Get a worker and remove it from the workers list.
  """
  @spec get(t) :: {:ok, {worker, t}} | {:empty, t}
  def get(%Stash{workers: []} = stash),
    do: {:empty, stash}
  def get(%Stash{workers: [worker|rest]} = stash),
    do: {:ok, {worker, %{stash | workers: rest}}}

  @doc """
  Add a worker to the workers list.
  """
  @spec return(t, worker) :: t
  def return(%Stash{workers: workers} = stash, worker),
    do: %{stash | workers: [worker|workers]}
end
