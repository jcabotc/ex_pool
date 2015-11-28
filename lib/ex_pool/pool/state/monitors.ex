defmodule ExPool.Pool.State.Monitors do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @doc """
  Creates an empty queue
  """
  @spec setup(State.t) :: State.t
  def setup(state), do: state
end
