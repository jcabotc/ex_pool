defmodule ExPool.State.Factory do
  @moduledoc """
  A factory of workers.

  This module defines a `ExPool.State.Factory` struct and the main functions
  to create and destroy workers.

  ## Fields

    * `sup` - simple_one_for_one supervisor to start and supervise workers
    * `total` - number of existing workers

  """

  @type worker :: pid

  @type sup   :: pid
  @type total :: non_neg_integer

  @type t :: %__MODULE__{
    sup:   sup,
    total: total
  }

  defstruct sup:   nil,
            total: 0

  alias ExPool.State.Factory
  alias ExPool.State.Factory.Supervisor, as: WorkersSupervisor

  @doc """
  Builds a new Factory struct with the given configuration.

  ## Configuration options

    * `:worker_mod` - (Required) worker module that fits on a supervision tree

  """
  @spec new(opts :: [Keyword]) :: t
  def new(opts) do
    worker_mod = Keyword.fetch!(opts, :worker_mod)
    {:ok, sup} = WorkersSupervisor.start_link(worker_mod)

    %Factory{sup: sup}
  end

  @doc """
  Creates a new worker.
  """
  @spec create(t) :: {worker, t}
  def create(%Factory{sup: sup, total: total} = factory) do
    {:ok, worker} = WorkersSupervisor.start_child(sup)

    {worker, %{factory | total: total + 1}}
  end

  @doc """
  Destroys a worker.
  """
  @spec destroy(t, worker) :: {t}
  def destroy(%Factory{sup: sup, total: total} = factory, worker) do
    WorkersSupervisor.stop_child(sup, worker)

    %{factory | total: total - 1}
  end

  @doc """
  Informs the factory a worker is dead.
  """
  @spec report_death(t) :: {t}
  def report_death(%Factory{total: total} = factory) do
    %{factory | total: total - 1}
  end
end
