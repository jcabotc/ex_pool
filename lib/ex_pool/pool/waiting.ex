defmodule ExPool.Pool.Waiting do
  @moduledoc """
  Manages the queue of waiting requests of the pool.
  """

  @doc """
  Creates an empty queue.
  """
  @spec setup(State.t) :: State.t
  def setup(state) do
    %{state | waiting: :queue.new}
  end

  @doc """
  Adds an item to the queue.
  """
  @spec push(State.t, item :: any) :: State.t
  def push(%{waiting: waiting} = state, item) do
    %{state | waiting: :queue.in(item, waiting)}
  end

  @doc """
  Removes an item from the queue.
  """
  def keep(%{waiting: waiting} = state, filter) do
    %{state | waiting: :queue.filter(filter, waiting)}
  end

  @doc """
  Pops an item from the queue.
  """
  @spec pop(State.t) :: {:ok, {item :: any, State.t}} | {:empty, State.t}
  def pop(%{waiting: waiting} = state) do
    case :queue.out(waiting) do
      {{:value, item}, new_waiting} -> {:ok, {item, %{state | waiting: new_waiting}}}
      {:empty, _queue}              -> {:empty, state}
    end
  end

end
