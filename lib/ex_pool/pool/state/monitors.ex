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
  Adds the given worker to the state monitors with its tag and reference.
  """
  @spec add(State.t, worker :: pid, tag :: atom, reference) :: State.t
  def add(%{monitors: monitors} = state, worker, tag, ref) do
    :ets.insert(monitors, {{tag, worker}, ref})

    state
  end

  @doc """
  Gets a worker and its tag from a reference.
  """
  @spec pid_from_ref(State.t, reference) :: {:ok, {tag :: atom, pid}} | :not_found
  def pid_from_ref(%{monitors: monitors}, ref) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[{tag, worker}]] -> {:ok, {tag, worker}}
      []                -> :not_found
    end
  end

  @doc """
  Removes the given worker and tag from the state monitors
  """
  @spec forget(State.t, worker :: pid, tag :: atom) :: State.t
  def forget(%{monitors: monitors} = state, worker, tag) do
    :ets.delete(monitors, {tag, worker})

    state
  end
end
