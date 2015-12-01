defmodule ExPool.State.Workers.Supervisor do
  @moduledoc """
  Supervisor the pool workers.
  """

  use Supervisor

  @doc """
  Creates a new supervisor.

  It receives as arguments the worker module, and a Keyword
  list of options that will be passed to Supervisor.start_link/3.
  """
  @spec start_link(worker_mod :: atom, opts :: [Keyword]) :: Supervisor.on_start
  def start_link(worker_mod, opts \\ []) do
    Supervisor.start_link(__MODULE__, worker_mod, opts)
  end

  @doc """
  Starts a new worker
  """
  @spec start_child(supervisor :: pid) :: Supervisor.on_start_child
  def start_child(sup) do
    Supervisor.start_child(sup, [])
  end

  @doc false
  def init(worker_mod) do
    children = [
      worker(worker_mod, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
