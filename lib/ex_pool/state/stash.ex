defmodule ExPool.State.Stash do
  @moduledoc """
  A stash of workers.

  This module defines a `ExPool.State.Stash` struct and the main functions
  to manage workers in a pool.

  ## Fields

    * `sup` - simple_one_for_one supervisor to start and supervise workers
    * `workers` - list of available workers

  """

  @type worker  :: pid
  @type workers :: [worker]

  @type t :: %__MODULE__{
    workers: workers,
  }

  defstruct workers: []

  alias ExPool.State.Stash

  @doc """
  Builds a new Stash struct with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) worker module that fits on a supervision tree

  """
  @spec new(opts :: [Keyword]) :: t
  def new(_opts), do: %Stash{}

  @doc """
  Returns the number of available workers.
  """
  @spec available(t) :: non_neg_integer
  def available(%Stash{workers: workers}), do: length(workers)

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
