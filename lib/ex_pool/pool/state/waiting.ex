defmodule ExPool.Pool.State.Waiting do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @doc """
  Creates an empty queue
  """
  @spec setup(State.t) :: State.t
  def setup(state) do
    %{state | queue: :queue.new}
  end

  @doc """
  Adds an item to the queue
  """
  @spec push(State.t, item :: any) :: State.t
  def push(%{queue: queue} = state, item) do
    %{state | queue: :queue.in(item, queue)}
  end

  @doc """
  Pops an item from the queue
  """
  @spec pop(State.t) :: {:ok, {item :: any, State.t}} | {:empty, State.t}
  def pop(%{queue: queue} = state) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} -> {:ok, {item, %{state | queue: new_queue}}}
      {:empty, _queue}            -> {:empty, state}
    end
  end

end
