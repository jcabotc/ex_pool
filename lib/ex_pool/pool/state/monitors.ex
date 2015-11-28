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
  @spec add(State.t, item :: any, reference) :: State.t
  def add(%{monitors: monitors} = state, item, ref) do
    :ets.insert(monitors, {item, ref})

    state
  end

  @doc """
  Gets a worker and its tag from a reference.
  """
  @spec pid_from_ref(State.t, reference) :: {:ok, item :: any} | :not_found
  def pid_from_ref(%{monitors: monitors}, ref) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[item]] -> {:ok, item}
      []       -> :not_found
    end
  end

  @doc """
  Removes the given worker and tag from the state monitors
  """
  @spec forget(State.t, item :: any) :: State.t
  def forget(%{monitors: monitors} = state, item) do
    :ets.delete(monitors, item)

    state
  end
end
