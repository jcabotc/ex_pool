defmodule ExPool.Pool.State.Monitors do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @doc """
  Creates an empty queue
  """
  @spec setup(State.t) :: State.t
  def setup(state) do
    %{state | monitors: :ets.new(:monitors, [:private])}
  end

  @doc """
  Monitors the given worker and stores the reference.
  """
  @spec watch(State.t, worker :: pid) :: State.t
  def watch(%{monitors: monitors} = state, worker) do
    worker_ref = Process.monitor(worker)
    :ets.insert(monitors, {worker, worker_ref})

    state
  end

  @doc """
  Gets a worker from the monitor reference.
  """
  @spec worker_from_ref(State.t, reference) :: worker :: pid
  def worker_from_ref(%{monitors: monitors}, worker_ref) do
    [[worker]] = :ets.match(monitors, {:"$1", worker_ref})

    worker
  end

  @doc """
  Demonitors the given worker and removes the reference.
  """
  @spec forget(State.t, worker :: pid) :: State.t
  def forget(%{monitors: monitors} = state, worker) do
    [{^worker, worker_ref}] = :ets.lookup(monitors, worker)

    Process.demonitor(worker_ref)
    :ets.delete(monitors, worker)

    state
  end
end
