defmodule ExPool.Pool.State.Workers do
  @moduledoc """
  Manages the available workers list of the pool.
  """

  alias ExPool.Pool.Supervisor, as: PoolSupervisor

  @doc """
  Starts the worker supervisor and initializes an empty workers list.
  """
  @spec setup(State.t) :: State.t
  def setup(%{worker_mod: worker_mod} = state) do
    {:ok, sup} = PoolSupervisor.start_link(worker_mod)

    %{state | sup: sup, workers: []}
  end

  @doc """
  Creates a new worker.
  """
  @spec create(State.t) :: State.t
  def create(%{workers: workers, sup: sup} = state) do
    {:ok, worker} = PoolSupervisor.start_child(sup)

    %{state | workers: [worker|workers]}
  end

  @doc """
  Get a worker and remove it from the workers list.
  """
  @spec get(State.t) :: {:ok, {pid, State.t}} | {:empty, State.t}
  def get(%{workers: []} = state) do
    {:empty, state}
  end
  def get(%{workers: [worker|rest]} = state) do
    {:ok, {worker, %{state | workers: rest}}}
  end

  @doc """
  Add a worker to the workers list.
  """
  @spec put(State.t, pid) :: State.t
  def put(%{workers: workers} = state, worker) do
    %{state | workers: [worker|workers]}
  end
end