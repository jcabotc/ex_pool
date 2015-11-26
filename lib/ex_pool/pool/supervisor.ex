defmodule ExPool.Pool.Supervisor do
  use Supervisor

  def start_link(worker_mod, opts \\ []) do
    Supervisor.start_link(__MODULE__, worker_mod, opts)
  end

  def start_child(sup) do
    Supervisor.start_child(sup, [])
  end

  def init(worker_mod) do
    children = [
      worker(worker_mod, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
