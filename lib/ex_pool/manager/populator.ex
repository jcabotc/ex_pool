defmodule ExPool.Manager.Populator do
  alias ExPool.State

  def populate(state) do
    remaining = State.size(state) - State.total_workers(state)
    populate(state, remaining, [])
  end

  defp populate(state, 0, workers) do
    {workers, state}
  end

  defp populate(state, remaining, workers) do
    {worker, state} = add(state)

    populate(state, remaining - 1, [worker|workers])
  end

  def add(state) do
    {worker, state} = State.create_worker(state)

    ref = Process.monitor(worker)
    state = State.add_monitor(state, {:worker, worker}, ref)

    {worker, state}
  end
end
